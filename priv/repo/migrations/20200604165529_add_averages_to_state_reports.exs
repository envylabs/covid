defmodule Rona.Repo.Migrations.AddAveragesToStateReports do
  use Ecto.Migration

  def change do
    alter table(:state_reports) do
      add :tested_avg_3, :integer, default: 0
      add :tested_avg_5, :integer, default: 0
      add :tested_avg_7, :integer, default: 0
      add :tested_delta_avg_3, :integer, default: 0
      add :tested_delta_avg_5, :integer, default: 0
      add :tested_delta_avg_7, :integer, default: 0
      add :confirmed_avg_3, :integer, default: 0
      add :confirmed_avg_5, :integer, default: 0
      add :confirmed_avg_7, :integer, default: 0
      add :confirmed_delta_avg_3, :integer, default: 0
      add :confirmed_delta_avg_5, :integer, default: 0
      add :confirmed_delta_avg_7, :integer, default: 0
      add :hospitalized_avg_3, :integer, default: 0
      add :hospitalized_avg_5, :integer, default: 0
      add :hospitalized_avg_7, :integer, default: 0
      add :hospitalized_delta_avg_3, :integer, default: 0
      add :hospitalized_delta_avg_5, :integer, default: 0
      add :hospitalized_delta_avg_7, :integer, default: 0
      add :deceased_avg_3, :integer, default: 0
      add :deceased_avg_5, :integer, default: 0
      add :deceased_avg_7, :integer, default: 0
      add :deceased_delta_avg_3, :integer, default: 0
      add :deceased_delta_avg_5, :integer, default: 0
      add :deceased_delta_avg_7, :integer, default: 0
    end
  end
end
