# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :blog_new,
  ecto_repos: [BlogNew.Repo],
  env: Mix.env()

# Configures the endpoint
config :blog_new, BlogNewWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "G/oCV4GBLLDk3XZNL18xJTKrIgPjLOLxPRqvLJEqVWhGM8+vdSHqsMMeCd9RbYoi",
  render_errors: [view: BlogNewWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BlogNew.PubSub,
  live_view: [signing_salt: "MtavZK0i"],
  force_ssl: [hsts: true]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure timezone database for timezone-based DateTime commands
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
