defmodule Rona.Cases.CountyReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "county_reports" do
    field :confirmed, :integer
    field :confirmed_avg_3, :integer
    field :confirmed_avg_5, :integer
    field :confirmed_avg_7, :integer
    field :confirmed_delta, :integer
    field :confirmed_delta_avg_3, :integer
    field :confirmed_delta_avg_5, :integer
    field :confirmed_delta_avg_7, :integer
    field :date, :date
    field :deceased, :integer
    field :deceased_avg_3, :integer
    field :deceased_avg_5, :integer
    field :deceased_avg_7, :integer
    field :deceased_delta, :integer
    field :deceased_delta_avg_3, :integer
    field :deceased_delta_avg_5, :integer
    field :deceased_delta_avg_7, :integer

    belongs_to :county, Rona.Places.County

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :date,
      :confirmed,
      :confirmed_avg_3,
      :confirmed_avg_5,
      :confirmed_avg_7,
      :confirmed_delta,
      :confirmed_delta_avg_3,
      :confirmed_delta_avg_5,
      :confirmed_delta_avg_7,
      :deceased,
      :deceased_avg_3,
      :deceased_avg_5,
      :deceased_avg_7,
      :deceased_delta,
      :deceased_delta_avg_3,
      :deceased_delta_avg_5,
      :deceased_delta_avg_7
    ])
    |> validate_required([:date, :confirmed, :deceased])
  end
end
