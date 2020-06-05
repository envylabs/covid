defmodule Rona.Repo.Migrations.AddAveragesToCountyReports do
  use Ecto.Migration

  def change do
    alter table(:county_reports) do
      add :confirmed_avg_3, :integer, default: 0
      add :confirmed_avg_5, :integer, default: 0
      add :confirmed_avg_7, :integer, default: 0
      add :confirmed_delta_avg_3, :integer, default: 0
      add :confirmed_delta_avg_5, :integer, default: 0
      add :confirmed_delta_avg_7, :integer, default: 0
      add :deceased_avg_3, :integer, default: 0
      add :deceased_avg_5, :integer, default: 0
      add :deceased_avg_7, :integer, default: 0
      add :deceased_delta_avg_3, :integer, default: 0
      add :deceased_delta_avg_5, :integer, default: 0
      add :deceased_delta_avg_7, :integer, default: 0
    end
  end
end
