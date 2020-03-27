defmodule Rona.Cases.StateReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "state_reports" do
    field :confirmed, :integer
    field :date, :date
    field :deceased, :integer

    belongs_to :state, Rona.Places.State

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:date, :confirmed, :deceased])
    |> validate_required([:date, :confirmed, :deceased])
  end
end
