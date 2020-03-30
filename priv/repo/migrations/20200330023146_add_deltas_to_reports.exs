defmodule Rona.Repo.Migrations.AddDeltasToReports do
  use Ecto.Migration

  def change do
    alter table(:reports) do
      add :confirmed_delta, :integer, default: 0
      add :deceased_delta, :integer, default: 0
    end

    alter table(:state_reports) do
      add :confirmed_delta, :integer, default: 0
      add :deceased_delta, :integer, default: 0
    end

    alter table(:county_reports) do
      add :confirmed_delta, :integer, default: 0
      add :deceased_delta, :integer, default: 0
    end
  end
end
