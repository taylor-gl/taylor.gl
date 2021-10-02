defmodule BlogNewWeb.WritingController do
  use BlogNewWeb, :controller

  alias BlogNew.Writing

  def index(conn, _params) do
    writings = Writing.list_writings!()
    render(conn, "index.html", writings: writings)
  end

  def show(conn, %{"slug" => slug}) do
    writing = Writing.get_writing!(slug)
    publish_date = writing.publish_date
    |> Calendar.strftime("%B %Y")

    render(conn, "show.html", publish_date: publish_date, writing: writing)
  end
end
