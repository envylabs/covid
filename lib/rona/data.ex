defmodule Rona.Data do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(state) do
    schedule_work(:refresh_data, 5_000)
    {:ok, state}
  end

  def handle_info(:refresh_data, state) do
    Logger.info("Updating data...")
    load()
    Logger.info("Data updated.")

    # 1 hour
    schedule_work(:refresh_data, 3_600_000)
    {:noreply, state}
  end

  def load do
    response =
      HTTPoison.get!(
        "https://raw.githubusercontent.com/datasets/covid-19/master/data/time-series-19-covid-combined.csv"
      )

    file = System.tmp_dir!() |> Path.join("covid-19.csv")
    File.write!(file, response.body)

    File.stream!(file)
    |> CSV.decode!(headers: true)
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

  defp schedule_work(event, delay) do
    Process.send_after(self(), event, delay)
  end
end
