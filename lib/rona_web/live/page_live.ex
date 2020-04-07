defmodule RonaWeb.PageLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:last_update, last_update())
      |> assign(:dates, date_range())

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      if fips = Map.get(params, "fips") do
        state = Rona.Places.get_state(fips)

        counties =
          Rona.Places.list_counties(state)
          |> Enum.filter(&(length(&1.reports) > 0))
          |> Enum.filter(&(&1.name != "Unassigned"))
          |> Enum.sort_by(
            &List.last(Enum.sort_by(&1.reports, fn r -> r.date end)).confirmed_delta
          )
          |> Enum.reverse()

        max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.CountyReport, state.name)

        socket
        |> assign(:state, state)
        |> assign(:counties, counties)
        |> assign(:max_value, max_value)
      else
        states =
          Rona.Places.list_states()
          |> Enum.sort_by(
            &List.last(Enum.sort_by(&1.reports, fn r -> r.date end)).confirmed_delta
          )
          |> Enum.reverse()

        max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport)

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

  defp date_range() do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    Rona.Cases.list_dates(Rona.Cases.CountyReport)
    |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))
  end

  defp last_update() do
    Rona.Cases.latest_update(Rona.Cases.CountyReport)
    |> Timex.Timezone.convert(Timex.Timezone.local())
  end
end
