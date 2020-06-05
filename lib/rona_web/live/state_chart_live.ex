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
    average = Map.get(session, "average", nil)

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
            do: Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport, dates.first),
            else: Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport, state, dates.first)
        end
      end

    socket =
      socket
      |> assign(:state, state)
      |> assign(:dates, dates)
      |> assign(:max_value, max_value)
      |> assign(:size, size)
      |> assign(:totals, totals)
      |> assign(:average, average)
      |> assign(:title, Map.get(session, "title", ""))

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    if assigns.size == "large",
      do: RonaWeb.ChartView.render("state_large.html", assigns),
      else: RonaWeb.ChartView.render("state.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key =
      "chart-#{socket.assigns.state.fips}-#{socket.assigns.totals}-#{socket.assigns.average}"

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

  defp build_data(%{dates: dates, state: state, totals: totals, average: average}) do
    Enum.map(dates, fn date ->
      report = Enum.find(state.reports, &(&1.date == date))

      if report do
        {c, d} =
          if totals,
            do: {"confirmed", "deceased"},
            else: {"confirmed_delta", "deceased_delta"}

        {c, d} =
          if average,
            do: {"#{c}_avg_#{average}", "#{d}_avg_#{average}"},
            else: {c, d}

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
