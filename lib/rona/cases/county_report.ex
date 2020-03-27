defmodule Rona.Cases.CountyReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "county_reports" do
    field :confirmed, :integer
    field :date, :date
    field :deceased, :integer

    belongs_to :county, Rona.Places.County

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:date, :confirmed, :deceased])
    |> validate_required([:date, :confirmed, :deceased])
  end
end
