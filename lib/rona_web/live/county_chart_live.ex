defmodule RonaWeb.CountyChartLive do
  use Phoenix.LiveView

  def mount(
        _params,
        %{
          "county" => fips,
          "start_date" => start_date,
          "end_date" => end_date,
          "max_value" => max_value
        } = session,
        socket
      ) do
    county = Rona.Places.get_county(fips)
    dates = Date.range(Date.from_iso8601!(start_date), Date.from_iso8601!(end_date))
    average = Map.get(session, "average", nil)

    socket =
      socket
      |> assign(:county, county)
      |> assign(:dates, dates)
      |> assign(:max_value, max_value)
      |> assign(:average, average)

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    RonaWeb.ChartView.render("county.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key = "chart-#{socket.assigns.county.fips}-#{socket.assigns.average}"

    data =
      Rona.Data.cache(cache_key, socket.assigns.dates.last, fn ->
        %{
          chart_data: build_data(socket.assigns),
          total_cases: Rona.Cases.max_confirmed(Rona.Cases.CountyReport, socket.assigns.county),
          total_deaths: Rona.Cases.max_deceased(Rona.Cases.CountyReport, socket.assigns.county)
        }
      end)

    assign(socket, data)
  end

  defp build_data(%{dates: dates, county: county, average: average}) do
    Enum.map(dates, fn date ->
      report = Enum.find(county.reports, &(&1.date == date))

      if report do
        {c, d} =
          if average,
            do: {"confirmed_delta_avg_#{average}", "deceased_delta_avg_#{average}"},
            else: {"confirmed_delta", "deceased_delta"}

        %{
          t: date,
          c: Map.get(report, String.to_atom(c)) - Map.get(report, String.to_atom(d)),
          d: Map.get(report, String.to_atom(d))
        }
      else
        %{t: date, c: 0, d: 0}
      end
    end)
    |> Jason.encode!()
  end
end
