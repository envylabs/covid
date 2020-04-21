defmodule Rona.Repo.Migrations.AddTestHospFieldsToStateReports do
  use Ecto.Migration

  def change do
    alter table(:state_reports) do
      add :tested, :integer, default: 0
      add :tested_delta, :integer, default: 0
      add :testing_rate, :float, default: 0
      add :positive_rate, :float, default: 0
      add :hospitalized, :integer, default: 0
      add :hospitalized_delta, :integer, default: 0
      add :hospitalization_rate, :float, default: 0
      add :death_rate, :float, default: 0
    end
  end
end
