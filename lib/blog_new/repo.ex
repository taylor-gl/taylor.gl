defmodule BlogNew.Repo do
  use Ecto.Repo,
    otp_app: :blog_new,
    adapter: Ecto.Adapters.Postgres
end
