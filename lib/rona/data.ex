defmodule Rona.Data do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(state) do
    schedule_work(:refresh_us_data, 5_000)
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
    load_usa()
    Logger.info("US data updated.")

    # 1 hour
    schedule_work(:refresh_us_data, 3_600_000)
    {:noreply, state}
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

  def load_usa do
    parse_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv")
    |> Enum.each(fn row ->
      fips = row["fips"]
      state = row["state"]
      date = Date.from_iso8601!(row["date"])
      cases = String.to_integer(row["cases"])
      deaths = String.to_integer(row["deaths"])

      Rona.Places.find_state(fips, state)
      |> Rona.Cases.file_report(date, cases, deaths)
    end)

    parse_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
    |> Enum.each(fn row ->
      fips = row["fips"]
      state = row["state"]
      county = row["county"]
      date = Date.from_iso8601!(row["date"])
      cases = String.to_integer(row["cases"])
      deaths = String.to_integer(row["deaths"])

      Rona.Places.find_county(fips, state, county)
      |> Rona.Cases.file_report(date, cases, deaths)
    end)
  end

  defp parse_csv(url) do
    response = HTTPoison.get!(url)

    file = System.tmp_dir!() |> Path.join("covid-19.csv")
    File.write!(file, response.body)

    File.stream!(file)
    |> CSV.decode!(headers: true)
  end

  defp schedule_work(event, delay) do
    Process.send_after(self(), event, delay)
  end
end
