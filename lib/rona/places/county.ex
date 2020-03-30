defmodule Rona.Places.County do
  use Ecto.Schema
  import Ecto.Changeset

  schema "counties" do
    field :fips, :string
    field :state, :string
    field :name, :string
    field :population, :integer

    has_many :reports, Rona.Cases.CountyReport

    timestamps()
  end

  @doc false
  def changeset(county, attrs) do
    county
    |> cast(attrs, [:fips, :state, :name, :population])
    |> validate_required([:state, :name])
  end
end
