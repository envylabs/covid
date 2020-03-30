defmodule Rona.Places.State do
  use Ecto.Schema
  import Ecto.Changeset

  schema "states" do
    field :fips, :string
    field :name, :string
    field :population, :integer

    has_many :reports, Rona.Cases.StateReport

    timestamps()
  end

  @doc false
  def changeset(state, attrs) do
    state
    |> cast(attrs, [:fips, :name, :population])
    |> validate_required([:fips, :name])
  end
end
