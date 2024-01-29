defmodule BlogNew.Repo.Migrations.AddStarredToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :starred, :boolean
    end
  end
end
