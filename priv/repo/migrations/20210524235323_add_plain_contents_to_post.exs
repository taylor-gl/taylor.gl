defmodule BlogNew.Repo.Migrations.AddPlainContentsToPost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :plain_content, :string
    end
  end
end
