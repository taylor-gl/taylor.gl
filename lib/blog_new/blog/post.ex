defmodule BlogNew.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlogNew.Repo
  alias BlogNew.Blog
  alias BlogNew.Blog.Post

  schema "posts" do
    field :markdown_filename, :string
    field :title, :string

    field :content, :string
    field :draft, :boolean
    field :publish_date, :date

    field :post_id

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :markdown_filename])
    |> validate_required([:post_id, :markdown_filename])
  end

  def crawl do
    # Crawl for new blog posts
    # TODO: Only choose draft posts in development mode
  end

  def post_from_file(filename) do
    post_id = filename |> String.replace_suffix(".md", "")

    new_post = %Blog.Post{
          content: nil,
          draft: nil,
          post_id: post_id,
          markdown_filename: filename,
          publish_date: nil,
          title: nil,
    }
    |> Repo.insert!()

    Path.join(["priv/content/posts", filename])
    |> File.read!
    |> split
    |> extract(new_post)
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
    IO.inspect(get_prop(props, "publish_date"))
    %{post |
      title: get_prop(props, "title"),
      publish_date: Timex.parse!(get_prop(props, "publish_date"), "{ISOdate}"),
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
