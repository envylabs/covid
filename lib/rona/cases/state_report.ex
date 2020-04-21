defmodule Rona.Cases.StateReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "state_reports" do
    field :date, :date
    field :tested, :integer
    field :tested_delta, :integer
    field :testing_rate, :float
    field :confirmed, :integer
    field :confirmed_delta, :integer
    field :positive_rate, :float
    field :hospitalized, :integer
    field :hospitalized_delta, :integer
    field :hospitalization_rate, :float
    field :deceased, :integer
    field :deceased_delta, :integer
    field :death_rate, :float

    belongs_to :state, Rona.Places.State

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :date,
      :tested,
      :tested_delta,
      :testing_rate,
      :confirmed,
      :confirmed_delta,
      :positive_rate,
      :hospitalized,
      :hospitalized_delta,
      :hospitalization_rate,
      :deceased,
      :deceased_delta,
      :death_rate
    ])
    |> validate_required([:date, :confirmed, :deceased])
  end
end
