defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  @tick_interval 200

  def mount(_params, _session, socket) do
    end_of_feb = Date.from_iso8601!("2020-02-29")

    dates =
      Rona.Cases.list_dates(Rona.Cases.CountyReport)
      |> Enum.filter(&(Date.compare(&1, end_of_feb) == :gt))

    socket =
      socket
      |> assign(:series, :confirmed)
      |> assign(:dates, dates)
      |> assign(:date_index, length(dates) - 1)
      |> assign(:max_date_index, length(dates) - 1)
      |> assign(:playing, false)

    {:ok, fetch_data(socket)}
  end

  def handle_event("prev", _, socket) do
    index = socket.assigns.date_index - 1
    index = if index < 0, do: length(socket.assigns.dates) - 1, else: index
    socket = assign(socket, :date_index, index)
    {:noreply, set_date(socket)}
  end

  def handle_event("next", _, socket) do
    index = socket.assigns.date_index + 1
    index = if index >= length(socket.assigns.dates), do: 0, else: index
    socket = assign(socket, :date_index, index)
    {:noreply, set_date(socket)}
  end

  def handle_event("play", _, socket) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, assign(socket, :playing, true)}
  end

  def handle_event("stop", _, socket) do
    {:noreply, assign(socket, :playing, false)}
  end

  def handle_event("update_settings", %{"series" => series}, socket) do
    socket = assign(socket, :series, String.to_atom(series))
    {:noreply, fetch_data(socket)}
  end

  def handle_info(:tick, socket) do
    if socket.assigns.playing, do: Process.send_after(self(), :tick, @tick_interval)
    handle_event("next", nil, socket)
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_data(socket) do
    date = Enum.at(socket.assigns.dates, socket.assigns.date_index)

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
    |> assign(:date, date)
    |> assign(:data, Jason.encode!(data))
  end

  defp set_date(socket) do
    date = Enum.at(socket.assigns.dates, socket.assigns.date_index)
    socket |> assign(:date, date)
  end
end
