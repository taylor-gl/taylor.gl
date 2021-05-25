defmodule BlogNew.Blog.RSS do
  import Ecto.Query, warn: false
  alias BlogNew.Repo
  alias BlogNew.Blog.Post
  alias BlogNew.Blog.ElixirRSS
  alias BlogNewWeb.Router.Helpers, as: Routes

  @rss_item_desc_length 240

  @doc """
  Called when posts are updated, generating an rss.xml.
  """
  def gen_rss() do
    # date offset to GMT, formatted in RFC 1123
    now_GMT_RFC1123 = Timex.now("GMT")
    |> Timex.format!("{RFC1123}")
    channel = ElixirRSS.channel("Taylor G. Lunt's Blog", "https://taylor.gl", "Taylor G. Lunt's blog.", now_GMT_RFC1123, "en-us")

    # build RSS items from database (do not include draft posts)
    query = from p in Post,
            where: p.draft == false
    items = Repo.all(query)
    |> Enum.sort(&Post.sort_posts/2)
    |> Enum.map(&(post_to_rss_item(&1)))

    feed = ElixirRSS.feed(channel, items)

    # write feed to xml file
    File.write!("priv/static/rss.xml", feed)
  end

  defp post_to_rss_item(%Post{plain_content: plain_content, title: title, publish_date: publish_date, markdown_filename: markdown_filename}) do
    # to form an RSS description, remove HTML tags from content, and then truncate to appropriate length
    # using regex to remove HTML tags from RSS is imperfect, but I think it will be fine in this case
    description = String.slice(plain_content, 0, @rss_item_desc_length - 3) <> "..."
    publish_datetime = DateTime.new!(publish_date, ~T[00:00:00], "GMT")
    publish_date_RFC1123 = Timex.format!(publish_datetime, "{RFC1123}")
    link = "https://taylor.gl" <> Routes.post_path(BlogNewWeb.Endpoint, :show, Post.post_id(markdown_filename))
    ElixirRSS.item(title, description, publish_date_RFC1123, link, link) # using link as the guid
  end

end
