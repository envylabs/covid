defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  def mount(_params, session, socket) do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))

    socket =
      socket
      |> assign(:series, :confirmed)
      |> assign(:population_scale, false)
      |> assign(:dates, dates)
      |> assign(:json_dates, Jason.encode!(dates))
      |> assign(:max_date_index, length(dates) - 1)
      |> assign(:zoom, Map.get(session, "fips", "00"))

    {:ok, fetch_map_data(socket)}
  end

  def handle_event("update_settings", params, socket) do
    socket =
      socket
      |> assign(:series, String.to_atom(params["series"]))
      |> assign(:population_scale, params["population_scale"] || false)

    {:noreply, fetch_map_data(socket)}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_map_data(socket) do
    cache_key =
      "map-#{socket.assigns.zoom}-#{socket.assigns.series}-#{socket.assigns.population_scale}"

    data =
      Rona.Data.cache(cache_key, List.last(socket.assigns.dates), fn ->
        Rona.Cases.for_dates(Rona.Cases.CountyReport, socket.assigns.dates)
        |> Enum.reduce(%{}, fn report, result ->
          if socket.assigns.zoom == "00" ||
               socket.assigns.zoom == String.slice(report.county.fips, 0, 2) do
            date_data = Map.get(result, report.date, %{})

            value =
              scale_value(
                Map.get(report, socket.assigns.series),
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
