defmodule BlogNew.Repo.Migrations.ChangePlainContentToText do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      modify :plain_content, :text
    end
  end
end
