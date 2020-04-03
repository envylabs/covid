defmodule RonaWeb.PageController do
  use RonaWeb, :controller

  def index(conn, _params) do
    states = Rona.Places.list_states()

    render(conn, "index.html", last_update: last_update(), states: states)
  end

  def show(conn, %{"fips" => fips}) do
    state = Rona.Places.get_state(fips)

    render(conn, "show.html", last_update: last_update(), state: state)
  end

  defp last_update() do
    Rona.Cases.latest_update(Rona.Cases.CountyReport)
    |> Timex.Timezone.convert(Timex.Timezone.local())
  end
end
