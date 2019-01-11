defmodule Drab.Mixfile do
  use Mix.Project
  @version "0.10.1"

  def project do
    [
      app: :drab,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      docs: [
        main: "Drab",
        logo: "priv/static/drab-400.png",
        # , filter_prefix: "Drab."
        extras: ["README.md", "LICENSE.md", "CHANGELOG.md", "CONTRIBUTING.md"],
        source_url: "https://github.com/grych/drab"
      ],
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :iex, :ex_unit]]
      # compilers: [:phoenix, :gettext] ++ Mix.compilers ++ [:drab]
    ]
  end

  def application do
    [
      mod: {Drab.Supervisor, []},
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :cowboy,
        :logger,
        :deppie,
        :floki,
        :gettext,
        :jason
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.2"},
      {:phoenix_html, "~> 2.13"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0 or ~> 2.2.2 or ~> 2.3"},
      {:plug_cowboy, "~> 1.0 or ~> 2.0"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:hound, "~> 1.0", only: [:dev, :test]},
      {:inch_ex, "~> 1.0", only: [:docs], runtime: false},
      {:deppie, "~> 1.0"},
      {:floki, ">= 0.20.2"},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev, :test], runtime: false},
      # {:credo, "~> 0.9.3", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.0"}
    ]
  end

  defp description() do
    """
    Remote controlled frontend framework for Phoenix.
    """
  end

  defp package() do
    [
      name: :drab,
      files: ["lib", "priv/templates/drab", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Tomek Gryszkiewicz"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/grych/drab",
        "Home" => "https://tg.pl/drab"
      }
    ]
  end
end
