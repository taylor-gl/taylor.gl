# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :blog_new,
  ecto_repos: [BlogNew.Repo],
  env: config_env()

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

# Using GeoLite2-Country database from MaxMind
config :geolix,
  databases: [
    %{
      id: :geolite2_country,
      adapter: Geolix.Adapter.MMDB2,
      source: "/var/lib/blog_new/geoip/GeoLite2-Country.mmdb"
    }
  ]

config :esbuild,
  version: "0.18.6",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
