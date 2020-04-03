defmodule RonaWeb.CountyChartLive do
  use Phoenix.LiveView

  def mount(_params, %{"county" => county}, socket) do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))

    max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.CountyReport, county.state)

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
    data =
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

    socket
    |> assign(:chart_data, Jason.encode!(data))
  end
end
