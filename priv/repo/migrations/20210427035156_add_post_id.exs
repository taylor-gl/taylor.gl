defmodule BlogNew.Repo.Migrations.AddContentDraftsDateToPost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :post_id, :string
    end

  end
end
