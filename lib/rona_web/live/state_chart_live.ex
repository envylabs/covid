defmodule RonaWeb.StateChartLive do
  use Phoenix.LiveView

  def mount(_params, %{"state" => state, "dates" => dates} = session, socket) do
    size = Map.get(session, "size", "small")
    totals = Map.get(session, "totals", false)

    max_value =
      if Map.get(session, "max_value") do
        Map.get(session, "max_value")
      else
        if totals do
          if size == "small",
            do: Rona.Cases.max_confirmed(Rona.Cases.StateReport),
            else: Rona.Cases.max_confirmed(Rona.Cases.StateReport, state)
        else
          if size == "small",
            do: Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport),
            else: Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport, state)
        end
      end

    socket =
      socket
      |> assign(:state, state)
      |> assign(:dates, dates)
      |> assign(:max_value, max_value)
      |> assign(:size, size)
      |> assign(:totals, totals)
      |> assign(:title, Map.get(session, "title", ""))

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    if assigns.size == "large",
      do: RonaWeb.ChartView.render("state_large.html", assigns),
      else: RonaWeb.ChartView.render("state.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key = "chart-#{socket.assigns.state.fips}-#{socket.assigns.totals}"

    data =
      Rona.Data.cache(cache_key, List.last(socket.assigns.dates), fn ->
        socket.assigns.dates
        |> Enum.map(fn date ->
          report = Enum.find(socket.assigns.state.reports, &(&1.date == date))

          if report do
            if socket.assigns.totals do
              %{
                t: date,
                c: report.confirmed - report.deceased,
                d: report.deceased
              }
            else
              %{
                t: date,
                c: report.confirmed_delta - report.deceased_delta,
                d: report.deceased_delta
              }
            end
          else
            %{t: date, c: 0, d: 0}
          end
        end)
        |> Jason.encode!()
      end)

    socket
    |> assign(:chart_data, data)
  end
end
