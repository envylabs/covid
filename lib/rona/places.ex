defmodule Rona.Places do
  @moduledoc """
  The Places context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Places.Location

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
end
