defmodule Rona.Places do
  @moduledoc """
  The Places context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Places.State
  alias Rona.Places.County

  @doc """
  Returns the list of states.

  ## Examples

      iex> list_states()
      [%State{}, ...]

  """
  def list_states do
    State
    |> where([s], s.population > 0)
    |> order_by(:name)
    |> preload(:reports)
    |> Repo.all()
  end

  @doc """
  Returns the list of counties for a state.

  ## Examples

      iex> list_counties(state)
      [%County{}, ...]

  """
  def list_counties(state) do
    County
    |> where([c], c.state == ^state.name)
    |> order_by(:name)
    |> preload(:reports)
    |> Repo.all()
  end

  def find_state(fips, name) do
    state =
      State
      |> where([s], s.fips == ^fips)
      |> preload(:reports)
      |> Repo.one() ||
        State
        |> where([s], s.name == ^name)
        |> preload(:reports)
        |> Repo.one()

    if state do
      state
    else
      %State{}
      |> State.changeset(%{
        fips: fips,
        name: name
      })
      |> Repo.insert!()
    end
  end

  def find_county(fips, state, name) do
    county =
      County
      |> where([c], c.fips == ^fips)
      |> preload(:reports)
      |> Repo.one() ||
        County
        |> where([c], c.name == ^name and c.state == ^state)
        |> preload(:reports)
        |> Repo.one()

    if county do
      county
    else
      %County{}
      |> County.changeset(%{
        fips: fips,
        state: state,
        name: name
      })
      |> Repo.insert!()
    end
  end

  def get_state(fips) do
    State
    |> where([s], s.fips == ^fips)
    |> preload(:reports)
    |> Repo.one()
  end

  def get_state_by_name(name) do
    State
    |> where([s], s.name == ^name)
    |> Repo.one()
  end

  def get_county(fips) do
    County
    |> where([s], s.fips == ^fips)
    |> preload(:reports)
    |> Repo.one()
  end

  def update_state(%State{} = state, attrs) do
    state
    |> State.changeset(attrs)
    |> Repo.update()
  end

  def update_county(%County{} = county, attrs) do
    county
    |> County.changeset(attrs)
    |> Repo.update()
  end
end
