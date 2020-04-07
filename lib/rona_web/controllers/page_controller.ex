defmodule RonaWeb.PageController do
  use RonaWeb, :controller

  def index(conn, _params) do
    states =
      Rona.Places.list_states()
      |> Enum.sort_by(&List.last(Enum.sort_by(&1.reports, fn r -> r.date end)).confirmed_delta)
      |> Enum.reverse()

    max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.StateReport)

    render(conn, "index.html",
      last_update: last_update(),
      states: states,
      dates: date_range(),
      max_value: max_value
    )
  end

  def show(conn, %{"fips" => fips}) do
    state = Rona.Places.get_state(fips)

    counties =
      Rona.Places.list_counties(state)
      |> Enum.filter(&(length(&1.reports) > 0))
      |> Enum.sort_by(&List.last(Enum.sort_by(&1.reports, fn r -> r.date end)).confirmed_delta)
      |> Enum.reverse()

    max_value = Rona.Cases.max_confirmed_delta(Rona.Cases.CountyReport, state.name)

    render(conn, "show.html",
      last_update: last_update(),
      state: state,
      counties: counties,
      dates: date_range(),
      max_value: max_value
    )
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
