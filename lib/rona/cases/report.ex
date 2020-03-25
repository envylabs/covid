defmodule Rona.Cases.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    field :active, :integer
    field :confirmed, :integer
    field :date, :date
    field :deceased, :integer
    field :recovered, :integer

    belongs_to :location, Rona.Places.Location

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:date, :confirmed, :recovered, :deceased, :active])
    |> validate_required([:date, :confirmed, :recovered, :deceased, :active])
  end
end
