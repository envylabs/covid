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
      |> assign(:population_scale, false)
      |> assign(:dates, dates)
      |> assign(:json_dates, Jason.encode!(dates))
      |> assign(:max_date_index, length(dates) - 1)

    {:ok, fetch_data(socket)}
  end

  def handle_event("update_settings", params, socket) do
    socket =
      socket
      |> assign(:series, String.to_atom(params["series"]))
      |> assign(:population_scale, params["population_scale"] || false)

    {:noreply, fetch_data(socket)}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end

  defp fetch_data(socket) do
    data =
      Rona.Cases.for_dates(Rona.Cases.CountyReport, socket.assigns.dates)
      |> Enum.reduce(%{}, fn report, result ->
        date_data = Map.get(result, report.date, %{})
        value = Map.get(report, socket.assigns.series)

        value =
          if socket.assigns.population_scale do
            if report.county.population > 0 do
              value / report.county.population * 100
            else
              0
            end
          else
            value
          end

        date_data = Map.put(date_data, report.county.fips, value)
        Map.put(result, report.date, date_data)
      end)

    socket
    |> assign(:data, Jason.encode!(data))
  end
end
