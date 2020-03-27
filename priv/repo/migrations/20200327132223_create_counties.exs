defmodule Rona.Repo.Migrations.CreateCounties do
  use Ecto.Migration

  def change do
    create table(:counties) do
      add :fips, :string
      add :state, :string
      add :name, :string

      timestamps()
    end

    create index(:counties, [:fips])
    create index(:counties, [:state])
  end
end
