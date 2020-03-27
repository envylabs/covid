defmodule Rona.Places.State do
  use Ecto.Schema
  import Ecto.Changeset

  schema "states" do
    field :fips, :string
    field :name, :string

    has_many :reports, Rona.Cases.StateReport

    timestamps()
  end

  @doc false
  def changeset(state, attrs) do
    state
    |> cast(attrs, [:fips, :name])
    |> validate_required([:fips, :name])
  end
end
