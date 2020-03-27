defmodule Rona.Repo.Migrations.CreateStates do
  use Ecto.Migration

  def change do
    create table(:states) do
      add :fips, :string
      add :name, :string

      timestamps()
    end

    create index(:states, [:fips])
  end
end
