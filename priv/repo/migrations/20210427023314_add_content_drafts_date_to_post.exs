defmodule BlogNew.Repo.Migrations.AddContentDraftsDateToPost do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :content, :string
      add :draft, :boolean
      add :publish_date, :date
    end

  end
end
