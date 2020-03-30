defmodule Rona.Cases.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    field :active, :integer
    field :confirmed, :integer
    field :confirmed_delta, :integer
    field :date, :date
    field :deceased, :integer
    field :deceased_delta, :integer
    field :recovered, :integer

    belongs_to :location, Rona.Places.Location

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :date,
      :confirmed,
      :confirmed_delta,
      :recovered,
      :deceased,
      :deceased_delta,
      :active
    ])
    |> validate_required([:date, :confirmed, :recovered, :deceased, :active])
  end
end
