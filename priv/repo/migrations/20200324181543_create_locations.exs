defmodule CovidGraphql.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :country, :string
      add :province_state, :string, default: ""
      add :latitude, :float
      add :longitude, :float

      timestamps()
    end
  end
end
