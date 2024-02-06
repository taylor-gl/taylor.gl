defmodule BlogNew.Blog.RSS do
  import Ecto.Query, warn: false
  alias BlogNew.Repo
  alias BlogNew.Blog.Post
  alias BlogNew.Blog.ElixirRSS
  alias BlogNew.Writing

  @rss_item_desc_length 240

  @doc """
  Called when posts are updated, generating an rss.xml.
  """
  def gen_rss() do
    # date offset to GMT, formatted in RFC 1123
    now_GMT_RFC1123 =
      Timex.now("GMT")
      |> Timex.format!("{RFC1123}")

    channel =
      ElixirRSS.channel(
        "Taylor G. Lunt's Blog",
        "https://taylor.gl",
        "Taylor G. Lunt's blog.",
        now_GMT_RFC1123,
        "en-us"
      )

    # build RSS items from database (do not include draft posts or draft writings)
    posts_query =
      from p in Post,
      where: p.draft == false

    writings_query = from w in Writing, where: w.draft == false

    posts = Repo.all(posts_query)
    writings = Repo.all(writings_query)

    sorted_items = (posts ++ writings) |> sort_items() |> Enum.map(&to_rss_item/1)

    ElixirRSS.feed(channel, sorted_items)
  end

  defp to_rss_item(%Post{
         plain_content: plain_content,
         title: title,
         publish_date: publish_date,
         markdown_filename: markdown_filename
       }) do
    # to form an RSS description, remove HTML tags from content, and then truncate to appropriate length
    # using regex to remove HTML tags from RSS is imperfect, but I think it will be fine in this case
    description = String.slice(plain_content, 0, @rss_item_desc_length - 3) <> "..."
    publish_datetime = DateTime.new!(publish_date, ~T[00:00:00], "GMT")
    publish_date_RFC1123 = Timex.format!(publish_datetime, "{RFC1123}")

    link = "https://taylor.gl/blog/#{Post.post_id(markdown_filename)}"

    # using link as the guid
    ElixirRSS.item(title, description, publish_date_RFC1123, link, link)
  end

  defp to_rss_item(%Writing{
        plain_content: plain_content,
        title: title,
        publish_date: publish_date,
        markdown_filename: markdown_filename
                   }) do
    # to form an RSS description, remove HTML tags from content, and then truncate to appropriate length
    # using regex to remove HTML tags from RSS is imperfect, but I think it will be fine in this case
    description = String.slice(plain_content, 0, @rss_item_desc_length - 3) <> "..."
    publish_datetime = DateTime.new!(publish_date, ~T[00:00:00], "GMT")
    publish_date_RFC1123 = Timex.format!(publish_datetime, "{RFC1123}")

    link = "https://taylor.gl/creative-writing/#{Writing.slug(markdown_filename)}"

    # using link as the guid
    ElixirRSS.item(title, description, publish_date_RFC1123, link, link)
  end

  defp sort_items(items) do
    items
    |> Enum.sort(fn a, b ->
      Date.compare(a.publish_date, b.publish_date) == :gt
    end)
  end
end
