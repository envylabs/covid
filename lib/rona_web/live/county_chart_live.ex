defmodule RonaWeb.CountyChartLive do
  use Phoenix.LiveView

  def mount(_params, %{"county" => county, "dates" => dates, "max_value" => max_value}, socket) do
    total_cases = Rona.Cases.max_confirmed(Rona.Cases.CountyReport, county)
    total_deaths = Rona.Cases.max_deceased(Rona.Cases.CountyReport, county)

    socket =
      socket
      |> assign(:county, county)
      |> assign(:dates, dates)
      |> assign(:max_value, max_value)
      |> assign(:total_cases, total_cases)
      |> assign(:total_deaths, total_deaths)

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    RonaWeb.ChartView.render("county.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key = "chart-#{socket.assigns.county.fips}"

    data =
      Rona.Data.cache(cache_key, List.last(socket.assigns.dates), fn ->
        socket.assigns.dates
        |> Enum.map(fn date ->
          report = Enum.find(socket.assigns.county.reports, &(&1.date == date))

          if report,
            do: %{
              t: date,
              c: report.confirmed_delta - report.deceased_delta,
              d: report.deceased_delta
            },
            else: %{t: date, c: 0, d: 0}
        end)
        |> Jason.encode!()
      end)

    socket
    |> assign(:chart_data, data)
  end
end
