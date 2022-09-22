defmodule BlogNewWeb.ErrorController do
  use BlogNewWeb, :controller

  def not_found(conn, _params) do
    send_resp(conn, 404, "Not Found")
  end
end
