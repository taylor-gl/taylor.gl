defmodule BlogNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :blog_new,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: ["lib", "test/support"],
      start_permanent: true,
      aliases: aliases(),
      deps: deps(),
      releases: [
        blog_new: [
          include_executables_for: [:unix],
          applications: [blog_new: :permanent]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BlogNew.Application, []},
      extra_applications: [:geolix, :logger, :runtime_tools, :yamerl]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.17.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 0.6.2"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:earmark, "~> 1.4.46"},
      {:yamerl, "~> 0.10"},
      {:tzdata, "~> 1.1"},
      {:timex, "~> 3.7"},
      # To fix an error with 1.1.6
      {:ssl_verify_fun, "~> 1.1.7"},
      {:logger_file_backend, "0.0.13"},
      {:geolix, "~> 2.0"},
      {:geolix_adapter_mmdb2, "~> 0.6.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
