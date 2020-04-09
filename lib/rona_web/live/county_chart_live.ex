defmodule RonaWeb.CountyChartLive do
  use Phoenix.LiveView

  def mount(_params, %{"county" => county, "dates" => dates, "max_value" => max_value}, socket) do
    socket =
      socket
      |> assign(:county, county)
      |> assign(:dates, dates)
      |> assign(:max_value, max_value)

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    RonaWeb.ChartView.render("county.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key = "chart-#{socket.assigns.county.fips}"

    data =
      Rona.Data.cache(cache_key, List.last(socket.assigns.dates), fn ->
        %{
          chart_data: build_data(socket.assigns),
          total_cases: Rona.Cases.max_confirmed(Rona.Cases.CountyReport, socket.assigns.county),
          total_deaths: Rona.Cases.max_deceased(Rona.Cases.CountyReport, socket.assigns.county)
        }
      end)

    assign(socket, data)
  end

  defp build_data(%{dates: dates, county: county}) do
    Enum.map(dates, fn date ->
      report = Enum.find(county.reports, &(&1.date == date))

      if report,
        do: %{
          t: date,
          c: report.confirmed_delta - report.deceased_delta,
          d: report.deceased_delta
        },
        else: %{t: date, c: 0, d: 0}
    end)
    |> Jason.encode!()
  end
end
