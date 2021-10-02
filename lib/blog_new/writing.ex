defmodule BlogNew.Writing do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias BlogNew.{Repo, Writing}

  schema "writings" do
    field :markdown_filename, :string
    field :title, :string

    field :content, :string
    field :draft, :boolean
    field :publish_date, :date

    field :plain_content, :string

    field :era, Ecto.Enum, values: [:high_school, :university, :recent]

    field :type, Ecto.Enum, values: [:poem, :story]

    timestamps()
  end

  def changeset(writing, attrs) do
    writing
    |> cast(attrs, [
      :title,
      :markdown_filename,
      :content,
      :plain_content,
      :draft,
      :publish_date,
      :type
    ])
    |> validate_required([
      :title,
      :markdown_filename,
      :content,
      :plain_content,
      :draft,
      :publish_date,
      :type
    ])
    |> unique_constraint(:markdown_filename)
  end

  @doc """
  Returns the list of writings, sorted by publish date.
  Does not return drafts unless the current environment is the development environment (:dev).
  """
  def list_writings! do
    if Application.get_env(:blog_new, :env) == :dev do
      # crawl for new writings, and show drafts
      BlogNew.Writing.crawl()
      Repo.all(Writing)
      |> Enum.sort(&Writing.sort_writings/2)
    else
      query = from w in Writing,
              where: w.draft == false
      Repo.all(query)
      |> Enum.sort(&Writing.sort_writings/2)
    end
  end

  @doc """
  Gets a single writing, using the slug to calculate the filename.
  Does not return draft posts unless the current environment is the development
  environment (:dev).

  Raises `Ecto.NoResultsError` if the Post does not exist.
  """
  def get_writing!(slug) do
    filename = Writing.writing_filename(slug)
    if Application.get_env(:blog_new, :env) == :dev do
      # crawl for new writings, and show drafts
      BlogNew.Writing.crawl()
      Repo.get_by!(Writing, markdown_filename: filename)
    else
      Repo.get_by!(Writing, markdown_filename: filename, draft: false)
    end
  end

  def slug(filename) do
    String.replace_suffix(filename, ".md", "")
  end

  def writing_filename(slug) do
    slug <> ".md"
  end

  @doc """
  Does set-up for the writings, including crawling the filesystem for writings, and setting up RSS feeds.
  Should be run on server startup.
  """
  def init do
    BlogNew.Writing.crawl()
    BlogNew.Blog.RSS.gen_rss()
  end

  @doc """
  Crawls the filesystem, adding all creative writing to the database. Existing writings are updated.
  """
  def crawl do
    high_school_poems_and_changes =
      File.ls!("priv/content/poems/high-school")
      |> Enum.map(&Writing.writing_from_file(&1, :high_school, :poem))
      |> Enum.filter(& &1)

    university_poems_and_changes =
      File.ls!("priv/content/poems/university")
      |> Enum.map(&Writing.writing_from_file(&1, :university, :poem))
      |> Enum.filter(& &1)

    recent_poems_and_changes =
      File.ls!("priv/content/poems/recent")
      |> Enum.map(&Writing.writing_from_file(&1, :recent, :poem))
      |> Enum.filter(& &1)

    high_school_stories_and_changes =
      File.ls!("priv/content/stories/high-school")
      |> Enum.map(&Writing.writing_from_file(&1, :high_school, :story))
      |> Enum.filter(& &1)

    university_stories_and_changes =
      File.ls!("priv/content/stories/university")
      |> Enum.map(&Writing.writing_from_file(&1, :university, :story))
      |> Enum.filter(& &1)

    recent_stories_and_changes =
      File.ls!("priv/content/stories/recent")
      |> Enum.map(&Writing.writing_from_file(&1, :recent, :story))
      |> Enum.filter(& &1)

    writings_and_changes =
      high_school_poems_and_changes ++
        university_poems_and_changes ++
        recent_poems_and_changes ++
        high_school_stories_and_changes ++
        university_stories_and_changes ++
        recent_stories_and_changes

    writings_and_changes
    |> Enum.map(fn {writing, changes} -> Writing.changeset(writing, changes) end)
    # force true to update timestamp even if the writing hasn't changed
    |> Enum.map(fn changeset -> Repo.insert_or_update!(changeset, force: true) end)

    num_processed = Enum.count(writings_and_changes)
    Logger.info("#{num_processed} creative writings processed.")
  end

  def sort_writings(%Writing{publish_date: d1}, %Writing{publish_date: d2}) do
    Date.compare(d1, d2) == :gt
  end

  defp get_writing_dir(:high_school, :poem), do: "priv/content/poems/high-school/"
  defp get_writing_dir(:university, :poem), do: "priv/content/poems/university/"
  defp get_writing_dir(:recent, :poem), do: "priv/content/poems/recent/"
  defp get_writing_dir(:high_school, :story), do: "priv/content/stories/high-school/"
  defp get_writing_dir(:university, :story), do: "priv/content/stories/university/"
  defp get_writing_dir(:recent, :story), do: "priv/content/stories/recent/"

  @doc """
  Creates a writing struct from a markdown file for the writing, or finds it in the database.

  Returns a the writing struct and the list of changes that have been made to the writing since it
  was updated in the database.
  """
  def writing_from_file(filename, era, type) do
    if String.match?(filename, ~r/.md/) do
      full_filename = Path.join([get_writing_dir(era, type), filename])

      modified_date =
        full_filename
        |> File.stat!()
        |> Map.fetch!(:mtime)
        # returns a UTC time
        |> NaiveDateTime.from_erl!()

      # only process new files, or files where modified_date > database updated_at time
      writing =
        case Repo.get_by(Writing, markdown_filename: filename) do
          nil ->
            %Writing{markdown_filename: filename, era: era, type: type}

          existing ->
            if NaiveDateTime.compare(existing.updated_at, modified_date) == :lt do
              existing
            else
              nil
            end
        end

      if writing do
        Logger.info("Processing creative writing from file... #{filename}")

        changes =
          full_filename
          |> File.read!()
          |> split
          |> add_view_import
          |> extract

        {writing, changes}
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
    # this is so I don't have to type BlogNewWeb.WritingView.footnote just to add a footnote
    {props, "<% import BlogNewWeb.WritingView %>\n" <> content, plain_content}
  end

  defp extract({props, content, plain_content}) do
    # extract properties from the YAML and put them into the writing
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

  defp string_to_boolean("true"), do: true
  defp string_to_boolean("false"), do: false
end
