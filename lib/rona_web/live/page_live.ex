defmodule RonaWeb.PageLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    date_range = date_range()

    socket =
      socket
      |> assign(:last_update, last_update())
      |> assign(:dates, date_range)
      |> assign(:start_date, List.first(date_range))
      |> assign(:end_date, List.last(date_range))
      |> assign(:average, nil)

    {:ok, socket}
  end

  def handle_info({:update_average, average}, socket) do
    {:noreply, assign(socket, :average, average)}
  end

  def handle_params(params, _url, socket) do
    first_date = List.first(socket.assigns.dates)
    last_date = List.last(socket.assigns.dates)

    socket =
      if fips = Map.get(params, "fips") do
        state = Rona.Places.get_state(fips)

        counties =
          Rona.Places.list_counties(state)
          |> Enum.filter(&(length(&1.reports) > 0))
          |> Enum.filter(&(&1.name != "Unassigned"))
          |> Enum.sort_by(&cumulative_cases(&1.reports, last_date))
          |> Enum.reverse()
          |> Enum.take(8)

        max_value =
          Rona.Cases.max_confirmed_delta(Rona.Cases.CountyReport, state.name, first_date)

        socket
        |> assign(:state, state)
        |> assign(:counties, counties)
        |> assign(:max_value, max_value)
      else
        states =
          Rona.Places.list_states()
          |> Enum.sort_by(&cumulative_cases(&1.reports, last_date))
          |> Enum.reverse()

        max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport, first_date)

        socket
        |> assign(:state, nil)
        |> assign(:states, states)
        |> assign(:max_value, max_value)
      end

    {:noreply, socket}
  end

  def render(assigns) do
    if assigns.state do
      RonaWeb.PageView.render("show.html", assigns)
    else
      RonaWeb.PageView.render("index.html", assigns)
    end
  end

  defp cumulative_cases(reports, date) do
    report = Enum.find(reports, &(&1.date == date))

    if report, do: report.confirmed, else: 0
  end

  defp date_range() do
    Rona.Cases.list_dates(Rona.Cases.CountyReport)
    |> Enum.reverse()
    |> Enum.take(30)
    |> Enum.reverse()
    |> Enum.to_list()
  end

  defp last_update() do
    Rona.Cases.latest_update(Rona.Cases.CountyReport)
    |> Timex.Timezone.convert(Timex.Timezone.local())
  end
end
