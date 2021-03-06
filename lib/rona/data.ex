defmodule Rona.Data do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(state) do
    :ets.new(:data_cache, [:set, :public, :named_table])
    schedule_work(:refresh_us_data, 5_000)
    {:ok, state}
  end

  def cache(key, date, f) do
    cached_data = :ets.lookup(:data_cache, key)

    if cached_data == [] do
      data = f.()
      :ets.insert(:data_cache, {key, date, data})
      data
    else
      [{_, cache_date, data}] = cached_data

      if cache_date == date do
        data
      else
        data = f.()
        :ets.insert(:data_cache, {key, date, data})
        data
      end
    end
  end

  def clear_cache() do
    :ets.delete_all_objects(:data_cache)
  end

  def handle_info(:refresh_us_data, state) do
    next_day = Rona.Cases.list_dates(Rona.Cases.StateReport) |> List.last() |> Date.add(1)

    Logger.info("Updating US data...")
    # load_usa(:ny_times)
    load_usa(:johns_hopkins, next_day)
    update_calculated_fields(Rona.Cases.StateReport, next_day)
    update_calculated_fields(Rona.Cases.CountyReport, next_day)
    clear_cache()
    Logger.info("US data updated.")

    # 1 hour if we're caught up; otherwise, 1 minute
    delay = if Date.diff(Date.utc_today(), next_day) > 1, do: 60_000, else: 3_600_000
    schedule_work(:refresh_us_data, delay)
    {:noreply, state}
  end

  def update_day(date_str) do
    date = Date.from_iso8601!(date_str)
    load_usa(:johns_hopkins, date)
    update_calculated_fields(Rona.Cases.StateReport, date)
    update_calculated_fields(Rona.Cases.CountyReport, date)
    clear_cache()
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
    load_johns_hopkins_county_report(date)
    load_johns_hopkins_state_report(date)
  end

  def update_calculated_fields(report_type, date) do
    prev_reports =
      Date.range(Date.add(date, -7), Date.add(date, -1))
      |> Enum.map(&Rona.Cases.for_date(report_type, &1))

    reports = Rona.Cases.for_date(report_type, date)

    Enum.each(reports, fn report ->
      prev_report = find_previous_report(prev_reports, report)
      update_deltas(report_type, report, prev_report)
    end)

    Enum.each(reports, fn report ->
      prev_days = find_previous_reports(prev_reports, report)
      update_averages(report_type, report, prev_days, 3)
      update_averages(report_type, report, prev_days, 5)
      update_averages(report_type, report, prev_days, 7)
    end)
  end

  defp find_previous_report(list, %Rona.Cases.StateReport{state_id: id}) do
    list
    |> List.last()
    |> Enum.find(&(&1.state_id == id))
  end

  defp find_previous_report(list, %Rona.Cases.CountyReport{county_id: id}) do
    list
    |> List.last()
    |> Enum.find(&(&1.county_id == id))
  end

  defp find_previous_reports(list, %Rona.Cases.StateReport{state_id: id}) do
    list
    |> Enum.take(-6)
    |> Enum.map(fn daily_list ->
      Enum.find(daily_list, &(&1.state_id == id))
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp find_previous_reports(list, %Rona.Cases.CountyReport{county_id: id}) do
    list
    |> Enum.take(-6)
    |> Enum.map(fn daily_list ->
      Enum.find(daily_list, &(&1.county_id == id))
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp load_johns_hopkins_county_report(date) do
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
      s = Rona.Places.get_state_by_name(state)
      if s, do: Rona.Cases.file_report(s, date, cases, deaths)
    end)
  end

  defp load_johns_hopkins_state_report(date) do
    url =
      "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports_us"

    [year, month, day] = date |> Date.to_string() |> String.split("-")
    file = "#{month}-#{day}-#{year}.csv"

    parse_csv("#{url}/#{file}")
    |> Enum.each(fn row ->
      fips = row["FIPS"]
      state = row["Province_State"]

      tested =
        if row["People_Tested"] && String.length(row["People_Tested"]) > 0,
          do: String.to_integer(row["People_Tested"]),
          else: 0

      testing_rate =
        if row["Testing_Rate"] && String.length(row["Testing_Rate"]) > 0,
          do: String.to_float(row["Testing_Rate"]) / 1000,
          else: 0.0

      cases =
        if row["Confirmed"] && String.length(row["Confirmed"]) > 0,
          do: String.to_integer(row["Confirmed"]),
          else: 0

      positive_rate =
        if tested > 0,
          do: cases / tested * 100,
          else: 0.0

      hospitalized =
        if row["People_Hospitalized"] && String.length(row["People_Hospitalized"]) > 0,
          do: String.to_integer(row["People_Hospitalized"]),
          else: 0

      hospitalization_rate =
        if cases > 0,
          do: hospitalized / cases * 100,
          else: 0.0

      deaths =
        if row["Deaths"] && String.length(row["Deaths"]) > 0,
          do: String.to_integer(row["Deaths"]),
          else: 0

      death_rate =
        if cases > 0,
          do: deaths / cases * 100,
          else: 0.0

      if fips && String.length(fips) > 0 do
        Rona.Places.find_state(fips, state)
        |> Rona.Cases.file_report(
          date,
          tested,
          testing_rate,
          cases,
          positive_rate,
          hospitalized,
          hospitalization_rate,
          deaths,
          death_rate
        )
      end
    end)
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

  defp update_averages(Rona.Cases.StateReport, report, prev_reports, days) do
    prev_reports = Enum.take(prev_reports, -(days - 1))

    tested =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.tested) |> Enum.sum(),
        else: 0

    tested_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.tested_delta) |> Enum.sum(),
        else: 0

    confirmed =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.confirmed) |> Enum.sum(),
        else: 0

    confirmed_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.confirmed_delta) |> Enum.sum(),
        else: 0

    hospitalized =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.hospitalized) |> Enum.sum(),
        else: 0

    hospitalized_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.hospitalized_delta) |> Enum.sum(),
        else: 0

    deceased =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.deceased) |> Enum.sum(),
        else: 0

    deceased_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.deceased_delta) |> Enum.sum(),
        else: 0

    Rona.Cases.update_report(report, %{
      "tested_avg_#{days}": round((report.tested + tested) / days),
      "tested_delta_avg_#{days}": round((report.tested_delta + tested_delta) / days),
      "confirmed_avg_#{days}": round((report.confirmed + confirmed) / days),
      "confirmed_delta_avg_#{days}": round((report.confirmed_delta + confirmed_delta) / days),
      "hospitalized_avg_#{days}": round((report.hospitalized + hospitalized) / days),
      "hospitalized_delta_avg_#{days}":
        round((report.hospitalized_delta + hospitalized_delta) / days),
      "deceased_avg_#{days}": round((report.deceased + deceased) / days),
      "deceased_delta_avg_#{days}": round((report.deceased_delta + deceased_delta) / days)
    })
  end

  defp update_averages(_, report, prev_reports, days) do
    prev_reports = Enum.take(prev_reports, -(days - 1))

    confirmed =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.confirmed) |> Enum.sum(),
        else: 0

    confirmed_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.confirmed_delta) |> Enum.sum(),
        else: 0

    deceased =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.deceased) |> Enum.sum(),
        else: 0

    deceased_delta =
      if length(prev_reports) > 0,
        do: prev_reports |> Enum.map(& &1.deceased_delta) |> Enum.sum(),
        else: 0

    Rona.Cases.update_report(report, %{
      "confirmed_avg_#{days}": round((report.confirmed + confirmed) / days),
      "confirmed_delta_avg_#{days}": round((report.confirmed_delta + confirmed_delta) / days),
      "deceased_avg_#{days}": round((report.deceased + deceased) / days),
      "deceased_delta_avg_#{days}": round((report.deceased_delta + deceased_delta) / days)
    })
  end

  defp update_deltas(Rona.Cases.StateReport, report, prev_report) do
    {tested, confirmed, hospitalized, deceased} =
      if prev_report,
        do:
          {prev_report.tested, prev_report.confirmed, prev_report.hospitalized,
           prev_report.deceased},
        else: {0, 0, 0, 0}

    Rona.Cases.update_report(report, %{
      tested_delta: report.tested - tested,
      confirmed_delta: report.confirmed - confirmed,
      hospitalized_delta: report.hospitalized - hospitalized,
      deceased_delta: report.deceased - deceased
    })
  end

  defp update_deltas(_, report, prev_report) do
    {confirmed, deceased} =
      if prev_report,
        do: {prev_report.confirmed, prev_report.deceased},
        else: {0, 0}

    Rona.Cases.update_report(report, %{
      confirmed_delta: report.confirmed - confirmed,
      deceased_delta: report.deceased - deceased
    })
  end
end
