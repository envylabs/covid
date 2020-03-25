defmodule Rona.Places.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    field :country, :string
    field :latitude, :float
    field :longitude, :float
    field :province_state, :string

    has_many :reports, Rona.Cases.Report

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:country, :province_state, :latitude, :longitude])
    |> validate_required([:country, :latitude, :longitude])
  end
end
