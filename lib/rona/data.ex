defmodule Rona.Data do
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
        if String.length(row["Confirmed"]) > 0, do: String.to_integer(row["Confirmed"]), else: 0

      recovered =
        if String.length(row["Recovered"]) > 0, do: String.to_integer(row["Recovered"]), else: 0

      deaths = if String.length(row["Deaths"]) > 0, do: String.to_integer(row["Deaths"]), else: 0

      Rona.Places.find_location(country, state, lat, long)
      |> Rona.Cases.file_report(date, confirmed, recovered, deaths)
    end)
  end
end
