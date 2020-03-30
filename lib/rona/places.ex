defmodule Rona.Places do
  @moduledoc """
  The Places context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Places.Location
  alias Rona.Places.State
  alias Rona.Places.County

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations()
      [%Location{}, ...]

  """
  def list_locations do
    Location
    |> preload(:reports)
    |> Repo.all()
  end

  @doc """
  Returns the list of states.

  ## Examples

      iex> list_states()
      [%State{}, ...]

  """
  def list_states do
    State
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
    |> preload(:reports)
    |> Repo.all()
  end

  @doc """
  Finds a single location by country and state/province. If not found, creates a new one.

  ## Examples

      iex> find_location("US", "Florida")
      %Location{}

      iex> find_location("US", "Florida", 28.29, -82.59)
      %Location{}

  """
  def find_location(country, province_state \\ "", latitude \\ nil, longitude \\ nil) do
    location =
      Location
      |> where([l], l.country == ^country and l.province_state == ^province_state)
      |> preload(:reports)
      |> Repo.one()

    if location do
      location
    else
      %Location{}
      |> Location.changeset(%{
        country: country,
        province_state: province_state,
        latitude: latitude,
        longitude: longitude
      })
      |> Repo.insert!()
    end
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
