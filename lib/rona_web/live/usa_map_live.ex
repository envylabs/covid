defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  def mount(_params, session, socket) do
    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.reverse()
      |> Enum.take(30)
      |> Enum.reverse()

    socket =
      socket
      |> assign(:series, :confirmed)
      |> assign(:population_scale, false)
      |> assign(:average, nil)
      |> assign(:dates, dates)
      |> assign(:json_dates, Jason.encode!(dates))
      |> assign(:max_date_index, length(dates) - 1)
      |> assign(:zoom, Map.get(session, "fips", "00"))

    {:ok, fetch_map_data(socket)}
  end

  def handle_event("update_settings", params, socket) do
    average =
      if String.length(params["average"]) == 0,
        do: nil,
        else: String.to_integer(params["average"])

    socket =
      socket
      |> assign(:series, String.to_atom(params["series"]))
      |> assign(:population_scale, params["population_scale"] || false)
      |> assign(:average, average)

    send(socket.parent_pid, {:update_average, average})

    {:noreply, fetch_map_data(socket)}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_map_data(socket) do
    series = socket.assigns.series

    series =
      if socket.assigns.average,
        do: String.to_atom("#{series}_avg_#{socket.assigns.average}"),
        else: series

    cache_key = "map-#{socket.assigns.zoom}-#{series}-#{socket.assigns.population_scale}"

    data =
      Rona.Data.cache(cache_key, List.last(socket.assigns.dates), fn ->
        Rona.Cases.for_dates(Rona.Cases.CountyReport, socket.assigns.dates)
        |> Enum.reduce(%{}, fn report, result ->
          if socket.assigns.zoom == "00" ||
               socket.assigns.zoom == String.slice(report.county.fips, 0, 2) do
            date_data = Map.get(result, report.date, %{})

            value =
              scale_value(
                Map.get(report, series),
                socket,
                report.county.population
              )

            date_data = Map.put(date_data, report.county.fips, value)
            Map.put(result, report.date, date_data)
          else
            result
          end
        end)
        |> Jason.encode!()
      end)

    socket
    |> assign(:map_data, data)
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
