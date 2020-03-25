defmodule CovidGraphql.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :date, :date
      add :confirmed, :integer
      add :recovered, :integer
      add :deceased, :integer
      add :active, :integer
      add :location_id, references(:locations, on_delete: :nothing)

      timestamps()
    end

    create index(:reports, [:location_id])
  end
end
