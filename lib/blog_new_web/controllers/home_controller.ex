defmodule BlogNewWeb.HomeController do
  use BlogNewWeb, :controller

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
