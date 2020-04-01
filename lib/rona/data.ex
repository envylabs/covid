defmodule Rona.Data do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(state) do
    # schedule_work(:refresh_us_data, 5_000)
    # schedule_work(:refresh_global_data, 30_000)
    {:ok, state}
  end

  def handle_info(:refresh_global_data, state) do
    Logger.info("Updating global data...")
    load_global()
    Logger.info("Global data updated.")

    # 1 hour
    schedule_work(:refresh_global_data, 3_600_000)
    {:noreply, state}
  end

  def handle_info(:refresh_us_data, state) do
    Logger.info("Updating US data...")
    load_usa(:ny_times)
    Logger.info("US data updated.")

    # 1 hour
    schedule_work(:refresh_us_data, 3_600_000)
    {:noreply, state}
  end

  def update_day(date_str) do
    date = Date.from_iso8601!(date_str)
    load_usa(:johns_hopkins, date)
    update_deltas(Rona.Cases.StateReport)
    update_deltas(Rona.Cases.CountyReport)
  end

  def load_global do
    parse_csv(
      "https://raw.githubusercontent.com/datasets/covid-19/master/data/time-series-19-covid-combined.csv"
    )
    |> Enum.each(fn row ->
      country = row["Country/Region"]
      state = row["Province/State"] || ""
      {lat, _} = Float.parse(row["Lat"])
      {long, _} = Float.parse(row["Long"])
      date = Date.from_iso8601!(row["Date"])

      confirmed =
        if row["Confirmed"] && String.length(row["Confirmed"]) > 0,
          do: String.to_integer(row["Confirmed"]),
          else: 0

      recovered =
        if row["Recovered"] && String.length(row["Recovered"]) > 0,
          do: String.to_integer(row["Recovered"]),
          else: 0

      deaths =
        if row["Deaths"] && String.length(row["Deaths"]) > 0,
          do: String.to_integer(row["Deaths"]),
          else: 0

      Rona.Places.find_location(country, state, lat, long)
      |> Rona.Cases.file_report(date, confirmed, recovered, deaths)
    end)
  end

  def load_usa(:census) do
    parse_csv(
      "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv",
      :latin1
    )
    |> Enum.each(fn row ->
      state_fips = row["STATE"]
      county_fips = row["COUNTY"]
      state_name = row["STNAME"]
      county_name = row["CTYNAME"]
      population = String.to_integer(row["POPESTIMATE2019"])

      county_name =
        if String.ends_with?(county_name, "County"),
          do:
            String.split(county_name, " ")
            |> Enum.reverse()
            |> tl()
            |> Enum.reverse()
            |> Enum.join(" "),
          else: county_name

      if county_fips == "000" do
        Rona.Places.find_state(state_fips, state_name)
        |> Rona.Places.update_state(%{population: population})
      else
        Rona.Places.find_county("#{state_fips}#{county_fips}", state_name, county_name)
        |> Rona.Places.update_county(%{population: population})
      end
    end)
  end

  def load_usa(:ny_times) do
    parse_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv")
    |> Enum.each(fn row ->
      fips = row["fips"]
      state = row["state"]
      date = Date.from_iso8601!(row["date"])
      cases = String.to_integer(row["cases"])
      deaths = String.to_integer(row["deaths"])

      if fips && String.length(fips) > 0 && (cases > 0 || deaths > 0) do
        Rona.Places.find_state(fips, state)
        |> Rona.Cases.file_report(date, cases, deaths)
      end
    end)

    parse_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
    |> Enum.each(fn row ->
      fips = row["fips"]
      state = row["state"]
      county = row["county"]
      date = Date.from_iso8601!(row["date"])
      cases = String.to_integer(row["cases"])
      deaths = String.to_integer(row["deaths"])

      if fips && String.length(fips) > 0 && (cases > 0 || deaths > 0) do
        Rona.Places.find_county(fips, state, county)
        |> Rona.Cases.file_report(date, cases, deaths)
      end
    end)
  end

  def load_usa(:johns_hopkins, date \\ Date.utc_today()) do
    url =
      "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports"

    [year, month, day] = date |> Date.to_string() |> String.split("-")
    file = "#{month}-#{day}-#{year}.csv"

    parse_csv("#{url}/#{file}")
    |> Enum.reduce(%{}, fn row, states ->
      fips = if row["FIPS"], do: row["FIPS"], else: row["\uFEFFFIPS"]
      county = row["Admin2"]
      state = row["Province_State"]
      country = row["Country_Region"]
      cases = String.to_integer(row["Confirmed"])
      deaths = String.to_integer(row["Deaths"])

      if country == "US" do
        if fips && String.length(fips) > 0 && county && String.length(county) > 0 &&
             (cases > 0 || deaths > 0) do
          Rona.Places.find_county(fips, state, county)
          |> Rona.Cases.file_report(date, cases, deaths)
        end

        {total_cases, total_deaths} = Map.get(states, state, {0, 0})
        Map.put(states, state, {total_cases + cases, total_deaths + deaths})
      else
        states
      end
    end)
    |> Enum.each(fn {state, {cases, deaths}} ->
      Rona.Places.find_state("?", state)
      |> Rona.Cases.file_report(date, cases, deaths)
    end)
  end

  def update_deltas(report_type) do
    Rona.Cases.list_dates(report_type)
    |> Enum.reduce([], fn date, prev_reports ->
      reports = Rona.Cases.for_date(report_type, date)

      Enum.each(reports, fn report ->
        prev_report = find_matching_report(prev_reports, report)

        {confirmed, deceased} =
          if prev_report,
            do: {prev_report.confirmed, prev_report.deceased},
            else: {0, 0}

        Rona.Cases.update_report(report, %{
          confirmed_delta: report.confirmed - confirmed,
          deceased_delta: report.deceased - deceased
        })
      end)

      reports
    end)
  end

  defp find_matching_report(list, %Rona.Cases.Report{location_id: id}) do
    Enum.find(list, &(&1.location_id == id))
  end

  defp find_matching_report(list, %Rona.Cases.StateReport{state_id: id}) do
    Enum.find(list, &(&1.state_id == id))
  end

  defp find_matching_report(list, %Rona.Cases.CountyReport{county_id: id}) do
    Enum.find(list, &(&1.county_id == id))
  end

  defp parse_csv(url, encoding \\ :utf8) do
    response = HTTPoison.get!(url)

    file = System.tmp_dir!() |> Path.join("covid-19.csv")
    File.write!(file, response.body)

    File.stream!(file, encoding: encoding)
    |> CSV.decode!(headers: true)
  end

  defp schedule_work(event, delay) do
    Process.send_after(self(), event, delay)
  end
end
