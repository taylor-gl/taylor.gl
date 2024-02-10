defmodule BlogNewWeb.HomeController do
  use BlogNewWeb, :controller

  def show(conn, _params) do
    is_australian = BlogNew.Geolocation.is_user_from_australia?(conn.remote_ip)

    render(conn, "show.html", is_australian: is_australian)
  end
end
