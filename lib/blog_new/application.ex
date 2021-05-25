defmodule BlogNew.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BlogNew.Repo,
      # Start the Telemetry supervisor
      BlogNewWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BlogNew.PubSub},
      # Set up blog posts (including crawling the filesystem for posts, and setting up RSS feeds).
      Supervisor.child_spec({Task, &BlogNew.Blog.Post.init/0}, id: :post_worker),
      # Start the Endpoint (http/https)
      BlogNewWeb.Endpoint
      # Start a worker by calling: BlogNew.Worker.start_link(arg)
      # {BlogNew.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlogNew.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BlogNewWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
