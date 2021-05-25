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

    field :plain_content, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :markdown_filename, :content, :plain_content, :draft, :publish_date])
    |> validate_required([:title, :markdown_filename, :content, :plain_content, :draft, :publish_date])
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
  Does set-up for the posts, including crawling the filesystem for posts, and setting up RSS feeds.
  Should be run on server startup.
  """
  def init do
    BlogNew.Blog.Post.crawl()
    BlogNew.Blog.RSS.gen_rss()
  end

  @doc """
  Crawls the filesystem posts directory, adding all posts to the database. Existing posts are updated.
  """
  def crawl do
    posts_and_changes = File.ls!("priv/content/posts")
    |> Enum.map(&Post.post_from_file/1)
    |> Enum.filter(&(&1))


    posts_and_changes
    |> Enum.map(fn {post, changes} -> Post.changeset(post, changes) end)
    |> Enum.map(fn changeset -> Repo.insert_or_update!(changeset, force: true) end) # force true to update timestamp even if post hasn't changed

    num_processed = Enum.count(posts_and_changes)
    IO.puts("#{num_processed} blog posts processed.")
  end

  @doc """
  Sorts two posts based on their publish date.
  """
  def sort_posts(%Post{publish_date: d1}, %Post{publish_date: d2}) do
    Date.compare(d1, d2) == :gt
  end

  @doc """
  Creates a post struct from a markdown file for the post, or finds it in the database.

  Returns a the post struct and the list of changes that have been made to the post since it
  was updated in the database.
  """
  def post_from_file(filename) do
    if String.match?(filename, ~r/^\d+.md/) do
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
        changes = full_filename
        |> File.read!
        |> split
        |> add_view_import
        |> extract

        {post, changes}
      else
        nil # nil
      end
    end
  end

  defp split(markdown_data) do
    # Splits the frontmatter from the markdown and parses both. Parses the markdown section twice: once as HTML,
    # and one as plain text with all HTML tags, EEx tags, and newline characters removed. Expects a file like:
    #
    #---
    #title: Example Title
    #publish_date: 2021-04-26
    #draft: false
    #---
    #
    #This is the beginning of the *Markdown* section...
    [_, frontmatter, markdown] = String.split(markdown_data, ~r/\n?-{3,}\n/, parts: 3)
    {parse_yaml(frontmatter), Earmark.as_html!(markdown, escape: false, smartypants: false, postprocessor: &markdown_process_ast_leaf/1), format_plain_content(markdown)}
  end

  defp parse_yaml(yaml) do
    [parsed] = :yamerl_constr.string(yaml)
    parsed
  end

  defp format_plain_content(markdown) do
    markdown
    |> String.replace(~r/\s+/, " ") # replace e.g. newline characters, multiple spaces in a row, etc. with a single space
    |> String.replace(~r/<%=? footnote\("(.*?)".*?\) %>/, "\\1") # replace footnotes with their regular text, ignoring hover text
    |> String.replace(~r/<%=?(%[^>]|.)*%>/, "") # all other EEx tags
    |> String.replace(~r/<[^>]*>/, "") # HTML tags
    |> String.replace(~r/\[(.*?)\]\(.*?\)/, "\\1") # replace markdown links with just the link text
    |> String.replace(~r/[#*_~<>`&]+/, "") # remove certain characters
    |> String.replace(~r/\s+/, " ") # replace multiple whitespace characters with spaces again, in case removing tags created e.g. double spaces
    |> String.trim_leading()
  end

  defp add_view_import({props, content, plain_content}) do
    # add an alias to the content, so that the EEx parser can find functions in the view
    # this is so I don't have to type BlogNewWeb.PostView.footnote just to add a footnote
    {props, "<% import BlogNewWeb.PostView %>\n" <> content, plain_content}
  end

  defp extract({props, content, plain_content}) do
    # extract properties from the YAML and put them into the post
    %{title: get_prop(props, "title"),
      publish_date: Date.from_iso8601!(get_prop(props, "publish_date")),
      draft: string_to_boolean(get_prop(props, "draft")),
      content: content,
      plain_content: plain_content}
  end

  defp get_prop(props, key) do
    case :proplists.get_value(String.to_charlist(key), props) do
      :undefined -> nil
      x -> to_string(x)
    end
  end

  @doc """
  Adds my custom markdown tailwind classes to each tag generated by Earmark.

  For example, <h3> would become <h3 class="markdown-h3">
  """
  def markdown_process_ast_leaf(s) when is_bitstring(s), do: s
  def markdown_process_ast_leaf({tag, attrs, _, messages}) do
    {tag, attrs ++ [{"class", "markdown-#{tag}"}], nil, messages}
  end

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("false"), do: false

end
