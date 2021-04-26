defmodule BlogNew.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :markdown_filename, :string

      timestamps()
    end

  end
end
