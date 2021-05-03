defmodule BlogNew.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlogNew.Repo
  alias BlogNew.Blog.Post

  schema "posts" do
    field :markdown_filename, :string
    field :title, :string

    field :content, :string
    field :draft, :boolean
    field :publish_date, :date

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :markdown_filename, :content, :draft, :publish_date])
    |> validate_required([:title, :markdown_filename, :content, :draft, :publish_date])
    |> unique_constraint(:markdown_filename)
  end

  @doc """
  Calculates an integer post id from the given markdown filename.

  ## Examples

      iex> BlogNew.Blog.Post.post_id("13.md")
      13

  """
  def post_id(filename) do
    filename
    |> String.replace_suffix(".md", "")
    |> String.to_integer
  end

  @doc """
  Calculates markdown filename from given integer post id

  ## Examples

      iex> BlogNew.Blog.Post.post_filename(10)
      "10.md"

  """
  def post_filename(id) do
    if id |> is_integer do
      id |> Integer.to_string |> (&(&1 <> ".md")).()
    else
      id |> (&(&1 <> ".md")).()
    end
  end

  @doc """
  Crawls the filesystem posts directory, adding all posts to the database. Existing posts are updated.
  """
  def crawl do
    posts = File.ls!("priv/content/posts")
    |> Enum.map(&Post.post_from_file/1)
    |> Enum.filter(&(&1))

    posts
    |> Enum.sort(&Post.sort_posts/2)
    |> Enum.map(&Post.changeset(&1, %{}))
    |> Enum.map(fn changeset -> Repo.insert_or_update!(changeset, force: true) end) # force true to update timestamp even if post hasn't changed

    num_processed = Enum.count(posts)
    IO.puts("#{num_processed} blog posts processed.")
  end

  @doc """
  Sorts two posts based on their publish date.
  """
  def sort_posts(%Post{publish_date: d1}, %Post{publish_date: d2}) do
    Date.compare(d1, d2) == :gt
  end

  @doc """
  Creates a post struct from a markdown file for the post.
  """
  def post_from_file(filename) do
    # creates a struct from markdown file. Can be turned into a changeset and inserted into repo later.
    full_filename = Path.join(["priv/content/posts", filename])
    modified_date = full_filename
    |> File.stat!
    |> Map.fetch!(:mtime)
    |> NaiveDateTime.from_erl! # returns a UTC time

    # only process new files, or files where modified_date > database updated_at time
    post = case Repo.get_by(Post, markdown_filename: filename) do
      nil -> %Post{markdown_filename: filename}
      existing -> if NaiveDateTime.compare(existing.updated_at, modified_date) == :lt do existing else nil end
    end
    if post do
      IO.puts("Processing blog post from file... #{filename}")
      IO.puts("updated: #{post.updated_at}, modified: #{modified_date}, comparison: #{NaiveDateTime.compare(post.updated_at, modified_date)}")
      full_filename
      |> File.read!
      |> split
      |> extract(post)
    else
      post # nil
    end
  end

  defp split(markdown_data) do
    #Splits the frontmatter from the markdown and parses both. Expects a file like:
    #
    #---
    #title: Example Title
    #publish_date: 2021-04-26
    #draft: false
    #---
    #
    #This is the beginning of the *Markdown* section...
    [_, frontmatter, markdown] = String.split(markdown_data, ~r/\n?-{3,}\n/, parts: 3)
    {parse_yaml(frontmatter), Earmark.as_html!(markdown)}
  end

  defp parse_yaml(yaml) do
    [parsed] = :yamerl_constr.string(yaml)
    parsed
  end

  defp extract({props, content}, post) do
    # extract properties from the YAML and put them into the post
    %{post |
      title: get_prop(props, "title"),
      publish_date: Date.from_iso8601!(get_prop(props, "publish_date")),
      draft: string_to_boolean(get_prop(props, "draft")),
      content: content}
  end

  defp get_prop(props, key) do
    case :proplists.get_value(String.to_charlist(key), props) do
      :undefined -> nil
      x -> to_string(x)
    end
  end

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("false"), do: false

end
