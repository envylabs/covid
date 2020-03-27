defmodule Rona.Repo.Migrations.CreateCountyReports do
  use Ecto.Migration

  def change do
    create table(:county_reports) do
      add :date, :date
      add :confirmed, :integer
      add :deceased, :integer
      add :county_id, references(:counties, on_delete: :nothing)

      timestamps()
    end

    create index(:county_reports, [:county_id])
  end
end
