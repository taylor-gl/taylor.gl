defmodule BlogNewWeb.RssController do
  use BlogNewWeb, :controller

  def index(conn, _params) do
    feed = BlogNew.Blog.RSS.gen_rss()

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, feed)
  end
end
