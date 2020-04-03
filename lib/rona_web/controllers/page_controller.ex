defmodule RonaWeb.PageController do
  use RonaWeb, :controller

  def index(conn, _params) do
    last_update =
      Rona.Cases.latest_update(Rona.Cases.CountyReport)
      |> Timex.Timezone.convert(Timex.Timezone.local())

    states = Rona.Places.list_states()

    render(conn, "index.html", last_update: last_update, states: states)
  end

  def show(conn, %{"fips" => fips}) do
    last_update =
      Rona.Cases.latest_update(Rona.Cases.CountyReport)
      |> Timex.Timezone.convert(Timex.Timezone.local())

    state = Rona.Places.get_state(fips)

    render(conn, "show.html", last_update: last_update, state: state)
  end
end
