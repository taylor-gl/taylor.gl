defmodule BlogNew.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :markdown_filename, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :markdown_filename])
    |> validate_required([:title, :markdown_filename])
  end
end
