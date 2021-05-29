defmodule BlogNewWeb.PostController do
  use BlogNewWeb, :controller

  alias BlogNew.Blog
  alias BlogNew.Blog.Post

  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, "index.html", posts: posts)
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    publish_date = post.publish_date
    |> Calendar.strftime("%d %B %Y")

    render(conn, "show.html", post: post, publish_date: publish_date)
  end

  def phpmyadmin(conn, _params) do
    conn
    |> put_layout(false)
    |> render("phpmyadmin.html")
  end
end
