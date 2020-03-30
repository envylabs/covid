defmodule Rona.Repo.Migrations.AddPopulationToStatesAndCounties do
  use Ecto.Migration

  def change do
    alter table(:states) do
      add :population, :integer, default: 0
    end

    alter table(:counties) do
      add :population, :integer, default: 0
    end
  end
end
