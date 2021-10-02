defmodule BlogNew.Repo.Migrations.CreateWritings do
  use Ecto.Migration

  def change do
    create table(:writings) do
      add :markdown_filename, :string
      add :title, :string

      add :content, :string
      add :draft, :boolean
      add :publish_date, :date

      add :plain_content, :string

      add :era, :string

      add :type, :string

      timestamps()
    end
  end
end
