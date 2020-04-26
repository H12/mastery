defmodule MasteryPersistence.Repo.Migrations.AlterResponses do
  use Ecto.Migration

  def change do
    rename(table(:responses), :to, to: :question)
  end
end
