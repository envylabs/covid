defmodule Rona.Cases.StateReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "state_reports" do
    field :date, :date
    field :tested, :integer
    field :tested_avg_3, :integer
    field :tested_avg_5, :integer
    field :tested_avg_7, :integer
    field :tested_delta, :integer
    field :tested_delta_avg_3, :integer
    field :tested_delta_avg_5, :integer
    field :tested_delta_avg_7, :integer
    field :testing_rate, :float
    field :confirmed, :integer
    field :confirmed_avg_3, :integer
    field :confirmed_avg_5, :integer
    field :confirmed_avg_7, :integer
    field :confirmed_delta, :integer
    field :confirmed_delta_avg_3, :integer
    field :confirmed_delta_avg_5, :integer
    field :confirmed_delta_avg_7, :integer
    field :positive_rate, :float
    field :hospitalized, :integer
    field :hospitalized_avg_3, :integer
    field :hospitalized_avg_5, :integer
    field :hospitalized_avg_7, :integer
    field :hospitalized_delta, :integer
    field :hospitalized_delta_avg_3, :integer
    field :hospitalized_delta_avg_5, :integer
    field :hospitalized_delta_avg_7, :integer
    field :hospitalization_rate, :float
    field :deceased, :integer
    field :deceased_avg_3, :integer
    field :deceased_avg_5, :integer
    field :deceased_avg_7, :integer
    field :deceased_delta, :integer
    field :deceased_delta_avg_3, :integer
    field :deceased_delta_avg_5, :integer
    field :deceased_delta_avg_7, :integer
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
      :tested_avg_3,
      :tested_avg_5,
      :tested_avg_7,
      :tested_delta,
      :tested_delta_avg_3,
      :tested_delta_avg_5,
      :tested_delta_avg_7,
      :testing_rate,
      :confirmed,
      :confirmed_avg_3,
      :confirmed_avg_5,
      :confirmed_avg_7,
      :confirmed_delta,
      :confirmed_delta_avg_3,
      :confirmed_delta_avg_5,
      :confirmed_delta_avg_7,
      :positive_rate,
      :hospitalized,
      :hospitalized_avg_3,
      :hospitalized_avg_5,
      :hospitalized_avg_7,
      :hospitalized_delta,
      :hospitalized_delta_avg_3,
      :hospitalized_delta_avg_5,
      :hospitalized_delta_avg_7,
      :hospitalization_rate,
      :deceased,
      :deceased_avg_3,
      :deceased_avg_5,
      :deceased_avg_7,
      :deceased_delta,
      :deceased_delta_avg_3,
      :deceased_delta_avg_5,
      :deceased_delta_avg_7,
      :death_rate
    ])
    |> validate_required([:date, :confirmed, :deceased])
  end
end
