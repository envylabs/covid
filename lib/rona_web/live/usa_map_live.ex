defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))

    socket =
      socket
      |> assign(:series, :confirmed)
      |> assign(:dates, dates)
      |> assign(:json_dates, Jason.encode!(dates))
      |> assign(:max_date_index, length(dates) - 1)
      |> assign(:playing, false)

    {:ok, fetch_data(socket)}
  end

  def handle_event("update_settings", %{"series" => series}, socket) do
    socket = assign(socket, :series, String.to_atom(series))
    {:noreply, fetch_data(socket)}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_data(socket) do
    data =
      socket.assigns.dates
      |> Enum.reduce(%{}, fn d, result ->
        date_data =
          Rona.Cases.for_date(Rona.Cases.CountyReport, d)
          |> Enum.reduce(%{}, fn report, map ->
            Map.put(map, report.county.fips, Map.get(report, socket.assigns.series))
          end)

        Map.put(result, d, date_data)
      end)

    socket
    |> assign(:data, Jason.encode!(data))
  end
end
