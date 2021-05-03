defmodule BlogNew.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias BlogNew.Repo
  alias BlogNew.Blog.Post

  @doc """
  Returns the list of posts. Does not return draft posts unless the current
  environment is the development environment (:dev).

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    if Application.get_env(:blog_new, :env) == :dev do
      Repo.all(Post)
    else
      query = from p in Post,
              where: p.draft == false
      Repo.all(query)
    end
  end

  @doc """
  Gets a single post, using the post id number to calculate the filename.
  Does not return draft posts unless the current environment is the development
  environment (:dev).

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id) do
    filename = Post.post_filename(id)
    if Application.get_env(:blog_new, :env) == :dev do
      Repo.get_by!(Post, markdown_filename: filename)
    else
      Repo.get_by!(Post, markdown_filename: filename, draft: false)
    end
  end
end
