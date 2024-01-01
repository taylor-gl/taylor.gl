defmodule BlogNew.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger
  alias BlogNew.{Blog.Post, Repo}

  @header_id_max_length 30

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
    |> validate_required([
      :title,
      :markdown_filename,
      :content,
      :plain_content,
      :draft,
      :publish_date
    ])
    |> unique_constraint(:markdown_filename)
  end

  def post_id(filename) do
    filename
    |> String.replace_suffix(".md", "")
    |> String.to_integer()
  end

  def post_filename(id) do
    if id |> is_integer do
      id |> Integer.to_string() |> (&(&1 <> ".md")).()
    else
      id <> ".md"
    end
  end

  @doc """
  Does set-up for the posts, including crawling the filesystem for posts, and setting up RSS feeds.
  Should be run on server startup.
  """
  def init do
    BlogNew.Blog.Post.crawl()
  end

  @doc """
  Crawls the filesystem posts directory, adding all posts to the database. Existing posts are updated.
  """
  def crawl do
    posts_and_changes =
      Path.join(:code.priv_dir(:blog_new),"/content/posts")
      |> File.ls!()
      |> Enum.map(&Post.post_from_file/1)
      |> Enum.filter(& &1)

    posts_and_changes
    |> Enum.map(fn {post, changes} -> Post.changeset(post, changes) end)
    # force true to update timestamp even if post hasn't changed
    |> Enum.map(fn changeset -> Repo.insert_or_update!(changeset, force: true) end)

    num_processed = Enum.count(posts_and_changes)
    Logger.info("#{num_processed} blog posts processed.")
  end

  @doc """
  Sorts two posts based on their publish date.
  """
  def sort_posts(%Post{publish_date: d1}, %Post{publish_date: d2}) do
    Date.compare(d1, d2) == :gt
  end

  @doc """
  Creates a post struct from a markdown file for the post, or finds it in the database.

  Returns the post struct and the list of changes that have been made to the post since it
  was updated in the database.
  """
  def post_from_file(filename) do
    if String.match?(filename, ~r/^\d+.md/) do
      full_filename = Path.join([:code.priv_dir(:blog_new), "/content/posts", filename])

      modified_date =
        full_filename
        |> File.stat!()
        |> Map.fetch!(:mtime)
        # returns a UTC time
        |> NaiveDateTime.from_erl!()

      # only process new files, or files where modified_date > database updated_at time
      post =
        case Repo.get_by(Post, markdown_filename: filename) do
          nil ->
            %Post{markdown_filename: filename}

          existing ->
            if NaiveDateTime.compare(existing.updated_at, modified_date) == :lt do
              existing
            else
              nil
            end
        end

      if post do
        Logger.info("Processing blog post from file... #{filename}")

        changes =
          full_filename
          |> File.read!()
          |> split
          |> add_view_import
          |> add_anchors_to_headers
          |> extract

        {post, changes}
      else
        nil
      end
    end
  end

  defp split(markdown_data) do
    # Splits the frontmatter from the markdown and parses both. Parses the markdown section twice: once as HTML,
    # and one as plain text with all HTML tags, EEx tags, and newline characters removed. Expects a file like:
    #
    # ---
    # title: Example Title
    # publish_date: 2021-04-26
    # draft: false
    # ---
    #
    # This is the beginning of the *Markdown* section...
    [_, frontmatter, markdown] = String.split(markdown_data, ~r/\n?-{3,}\n/, parts: 3)

    {parse_yaml(frontmatter),
     Earmark.as_html!(markdown,
       escape: false,
       smartypants: false,
       postprocessor: &markdown_process_ast_leaf/1
     ), format_plain_content(markdown)}
  end

  defp parse_yaml(yaml) do
    [parsed] = :yamerl_constr.string(yaml)
    parsed
  end

  defp format_plain_content(markdown) do
    markdown
    # replace e.g. newline characters, multiple spaces in a row, etc. with a single space
    |> String.replace(~r/\s+/, " ")
    # replace footnotes with their regular text, ignoring hover text
    |> String.replace(~r/<%=? footnote\("(.*?)".*?\) %>/, "\\1")
    # all other EEx tags
    |> String.replace(~r/<%=?(%[^>]|.)*%>/, "")
    # HTML tags
    |> String.replace(~r/<[^>]*>/, "")
    # replace markdown links with just the link text
    |> String.replace(~r/\[(.*?)\]\(.*?\)/, "\\1")
    # remove certain characters
    |> String.replace(~r/[#*_~<>`&]+/, "")
    # replace multiple whitespace characters with spaces again, in case removing tags created e.g. double spaces
    |> String.replace(~r/\s+/, " ")
    |> String.trim_leading()
  end

  defp add_view_import({props, content, plain_content}) do
    # add an alias to the content, so that the EEx parser can find functions in the view
    # this is so I don't have to type BlogNewWeb.PostView.footnote just to add a footnote
    {props, "<% import BlogNewWeb.PostView %>\n" <> content, plain_content}
  end

  defp extract({props, content, plain_content}) do
    # extract properties from the YAML and put them into the post
    %{
      title: get_prop(props, "title"),
      publish_date: Date.from_iso8601!(get_prop(props, "publish_date")),
      draft: string_to_boolean(get_prop(props, "draft")),
      content: content,
      plain_content: plain_content
    }
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

  @doc """
  Adds unique ids to any header tags in the post content which do not contain other tags.
  Also adds an anchor to the beginning of the header. Uses the fontawesome glyph fa-link for the anchor link icon.

  For example, <h3 class="markdown-h3>Header title</h3> would become:
  <h3 class="markdown-h3" id="header-title"><a class="markdown-header-anchor" href="#header-title"><i class="markdown-header-anchor-img fas fa-link"></i></a>Header title</h3>
  """
  def add_anchors_to_headers({props, html, plain_content}) do
    # regex should be fine as we are only considering header tags which do not contain other tags
    new_html =
      Regex.replace(~r/<(h\d.*?)>(.*?)<(\/h\d)>/s, html, fn _, opening, content, closing ->
        id = header_id(content)

        "<#{opening} id=\"#{id}\"><a class=\"markdown-header-anchor\" href=\"\##{id}\"><i class=\"markdown-header-anchor-img fas fa-link\"></i></a>#{content}<#{closing}>"
      end)

    {props, new_html, plain_content}
  end

  defp header_id(header_content) do
    header_content
    |> String.to_charlist()
    # include only ascii characters
    |> Enum.filter(&(&1 in 32..127))
    |> List.to_string()
    |> String.downcase(:ascii)
    # keep only alphanumeric and space characters
    |> String.replace(~r/[^\w\s\d]/, "")
    # replace spaces with hyphens
    |> String.replace(~r/[\s]+/, "-")
    |> String.slice(0, @header_id_max_length)
  end

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("false"), do: false
end
