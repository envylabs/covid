defmodule RonaWeb.TrendChartLive do
  use Phoenix.LiveView

  def mount(
        _params,
        %{
          "state" => fips,
          "title" => title,
          "field" => field,
          "start_date" => start_date,
          "end_date" => end_date,
          "percent" => percent_field,
          "percent_label" => percent_label
        } = session,
        socket
      ) do
    state = Rona.Places.get_state(fips)
    dates = Date.range(Date.from_iso8601!(start_date), Date.from_iso8601!(end_date))
    average = Map.get(session, "average", nil)

    socket =
      socket
      |> assign(:state, state)
      |> assign(:dates, dates)
      |> assign(:title, title)
      |> assign(:field, field)
      |> assign(:percent_field, percent_field)
      |> assign(:percent_label, percent_label)
      |> assign(:average, average)

    {:ok, fetch_chart_data(socket)}
  end

  def render(assigns) do
    RonaWeb.ChartView.render("trend.html", assigns)
  end

  defp fetch_chart_data(socket) do
    cache_key =
      "chart-#{socket.assigns.state.fips}-#{socket.assigns.field}-#{socket.assigns.average}"

    data =
      Rona.Data.cache(cache_key, socket.assigns.dates.last, fn ->
        build_data(socket.assigns)
      end)

    assign(socket, data)
  end

  defp build_data(%{
         dates: dates,
         state: state,
         field: field,
         percent_field: percent_field,
         average: average
       }) do
    {field, field_delta} =
      if average,
        do: {"#{field}_avg_#{average}", "#{field}_delta_avg_#{average}"},
        else: {field, "#{field}_delta"}

    result =
      Enum.reduce(dates, %{chart_data: [], max_value: 0, percent_value: 0.0}, fn date, acc ->
        report = Enum.find(state.reports, &(&1.date == date))

        {c, d, p} =
          if report do
            c = Map.get(report, String.to_atom(field))
            d = Map.get(report, String.to_atom(field_delta))
            p = Map.get(report, String.to_atom(percent_field))

            d = if acc.max_value == 0, do: 0, else: d

            {c, d, p}
          else
            {0, 0, 0.0}
          end

        %{
          chart_data: acc.chart_data ++ [%{t: date, c: c, d: d}],
          max_value: max(acc.max_value, c),
          percent_value: max(acc.percent_value, p)
        }
      end)

    %{
      chart_data: Jason.encode!(result.chart_data),
      max_value: result.max_value,
      percent_value: result.percent_value
    }
  end
end
