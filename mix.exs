defmodule DailyLogos.MixProject do
  use Mix.Project

  def project do
    [
      app: :daily_logos,
      version: "1.13.6",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DailyLogos.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        test: :test,
        "test.unit": :test,
        "test.integ": :test,
        "test.all": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:open_api_spex, "~> 3.22"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:testcontainers, "~> 2.3", only: [:dev, :test]},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:dotenvy, "~> 1.1", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      seed: ["run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test.unit": [
        "test test/unit --no-start --color"
      ],
      "test.integ.run": [
        "ecto.migrate",
        "test test/integration --color"
      ],
      "test.integ": [
        "cmd MIX_ENV=test TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock mix testcontainers.run test.integ.run"
      ],
      "test.all": [
        "test.unit",
        "test.integ"
      ],
      "assets.setup": [
        "cmd --cd assets npm ci",
        "assets.fonts",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.fonts": [
        "cmd mkdir -p priv/static/assets/css/fonts",
        "cmd cp assets/node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff priv/static/assets/css/fonts/bootstrap-icons.woff",
        "cmd cp assets/node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2 priv/static/assets/css/fonts/bootstrap-icons.woff2"
      ],
      "assets.build": ["compile", "assets.fonts", "tailwind daily_logos", "esbuild daily_logos"],
      "assets.deploy": [
        "assets.fonts",
        "tailwind daily_logos --minify",
        "esbuild daily_logos --minify",
        "phx.digest"
      ],
      precommit: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict"
      ]
    ]
  end
end
