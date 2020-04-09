defmodule RonaWeb.StateChartLive do
  use Phoenix.LiveView

  def mount(
        _params,
        %{"state" => fips, "start_date" => start_date, "end_date" => end_date} = session,
        socket
      ) do
    state = Rona.Places.get_state(fips)
    dates = Date.range(Date.from_iso8601!(start_date), Date.from_iso8601!(end_date))
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
      Rona.Data.cache(cache_key, socket.assigns.dates.last, fn ->
        %{
          chart_data: build_data(socket.assigns),
          total_cases: Rona.Cases.max_confirmed(Rona.Cases.StateReport, socket.assigns.state),
          total_deaths: Rona.Cases.max_deceased(Rona.Cases.StateReport, socket.assigns.state)
        }
      end)

    assign(socket, data)
  end

  defp build_data(%{dates: dates, state: state, totals: totals}) do
    Enum.map(dates, fn date ->
      report = Enum.find(state.reports, &(&1.date == date))

      if report do
        if totals do
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
  end
end
