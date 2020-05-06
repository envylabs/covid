defmodule Rona.Repo.Migrations.RemoveUnusedTables do
  use Ecto.Migration

  def change do
    drop table(:reports)
    drop table(:locations)
  end
end
