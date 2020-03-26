defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  @tick_interval 500

  def mount(_params, _session, socket) do
    dates = Rona.Cases.list_dates()

    socket =
      socket
      |> assign(:dates, dates)
      |> assign(:date_index, length(dates) - 1)
      |> assign(:playing, false)

    {:ok, fetch_data(socket)}
  end

  def handle_event("prev", _, socket) do
    index = socket.assigns.date_index - 1
    index = if index < 0, do: length(socket.assigns.dates) - 1, else: index
    socket = assign(socket, :date_index, index)
    {:noreply, fetch_data(socket)}
  end

  def handle_event("next", _, socket) do
    index = socket.assigns.date_index + 1
    index = if index >= length(socket.assigns.dates), do: 0, else: index
    socket = assign(socket, :date_index, index)
    {:noreply, fetch_data(socket)}
  end

  def handle_event("play", _, socket) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, assign(socket, :playing, true)}
  end

  def handle_event("stop", _, socket) do
    {:noreply, assign(socket, :playing, false)}
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
      Rona.Cases.for_date(date)
      |> Enum.reduce(%{}, fn report, map ->
        Map.put(map, "12#{String.pad_leading(Integer.to_string(report.location.id), 3, "0")}", [
          report.active,
          report.deceased
        ])
      end)

    socket
    |> assign(:date, date)
    |> assign(:data, Jason.encode!(data))
  end
end
