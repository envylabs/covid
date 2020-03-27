defmodule Rona.Repo.Migrations.CreateStateReports do
  use Ecto.Migration

  def change do
    create table(:state_reports) do
      add :date, :date
      add :confirmed, :integer
      add :deceased, :integer
      add :state_id, references(:states, on_delete: :nothing)

      timestamps()
    end

    create index(:state_reports, [:state_id])
  end
end
