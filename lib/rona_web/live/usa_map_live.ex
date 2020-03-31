defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))

    states = Rona.Places.list_states()
    selected_state = List.first(states)

    counties = Rona.Places.list_counties(selected_state)
    selected_county = List.first(counties)

    socket =
      socket
      |> assign(:series, :confirmed)
      |> assign(:population_scale, false)
      |> assign(:dates, dates)
      |> assign(:json_dates, Jason.encode!(dates))
      |> assign(:max_date_index, length(dates) - 1)
      |> assign(:states, states)
      |> assign(:selected_state, selected_state.id)
      |> assign(:counties, counties)
      |> assign(:selected_county, selected_county.id)

    {:ok, socket |> fetch_map_data() |> fetch_location_data()}
  end

  def handle_event("select_location", %{"state" => state_id, "county" => county_id}, socket) do
    state_id = String.to_integer(state_id)
    county_id = String.to_integer(county_id)

    selected_state = Enum.find(socket.assigns.states, &(&1.id == state_id))

    counties =
      if state_id == socket.assigns.selected_state,
        do: socket.assigns.counties,
        else: Rona.Places.list_counties(selected_state)

    selected_county = Enum.find(counties, &(&1.id == county_id)) || List.first(counties)

    socket =
      socket
      |> assign(:selected_state, selected_state.id)
      |> assign(:counties, counties)
      |> assign(:selected_county, selected_county.id)

    {:noreply, fetch_location_data(socket)}
  end

  def handle_event("update_settings", params, socket) do
    socket =
      socket
      |> assign(:series, String.to_atom(params["series"]))
      |> assign(:population_scale, params["population_scale"] || false)

    {:noreply, socket |> fetch_map_data() |> fetch_location_data()}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_map_data(socket) do
    data =
      Rona.Cases.for_dates(Rona.Cases.CountyReport, socket.assigns.dates)
      |> Enum.reduce(%{}, fn report, result ->
        date_data = Map.get(result, report.date, %{})

        value =
          scale_value(Map.get(report, socket.assigns.series), socket, report.county.population)

        date_data = Map.put(date_data, report.county.fips, value)
        Map.put(result, report.date, date_data)
      end)

    socket
    |> assign(:map_data, Jason.encode!(data))
  end

  defp fetch_location_data(socket) do
    county = Enum.find(socket.assigns.counties, &(&1.id == socket.assigns.selected_county))

    data =
      county.reports
      |> Enum.reduce(%{}, fn report, result ->
        date_data = %{
          confirmed: scale_value(report.confirmed, socket, county.population),
          deceased: scale_value(report.deceased, socket, county.population)
        }

        Map.put(result, report.date, date_data)
      end)

    socket
    |> assign(:location_data, Jason.encode!(data))
  end

  defp scale_value(value, socket, population) do
    if socket.assigns.population_scale do
      if population > 0,
        do: round(value / population * 100_000),
        else: 0
    else
      value
    end
  end
end
