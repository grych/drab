defmodule Drab.Mixfile do
  use Mix.Project
  @version "0.6.2"

  def project do
    [app: :drab,
     version: @version,
     elixir: ">= 1.4.0 and < 1.5.0 or >= 1.5.1 and < 1.7.0", # a bug in EEx in 1.5.0
     # elixir: "~> 1.5.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps(),
     description: description(),
     package: package(),
     docs: [main: "Drab", logo: "priv/static/drab-400.png",
      extras: ["README.md", "LICENSE.md", "CHANGELOG.md", "CONTRIBUTING.md"]], # , filter_prefix: "Drab."
     compilers: [:phoenix, :gettext] ++ Mix.compilers
     # compilers: [:phoenix, :gettext] ++ Mix.compilers ++ [:drab]
   ]
  end

  def application do
    [mod: {Drab.Supervisor, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :deppie]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev),  do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:ex_doc, "~> 0.18", only: :dev, runtime: false},
     {:hound, "~> 1.0", only: [:dev, :test]},
     # {:inch_ex, "~> 0.5", only: [:dev, :test, :docs]},
     {:deppie, "~> 1.0"},
     {:floki, "~> 0.17"}
   ]
  end

  defp description() do
    """
    Plugin to the Phoenix Framework to access the User Interface in the browser directly from the server side.
    """
  end

  defp package() do
    [
      name: :drab,
      # files: ["lib", "priv", "test", "mix.exs", "README*", "LICENSE*"],
      files: ["lib", "priv/templates/drab", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Tomek Gryszkiewicz"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/grych/drab",
        "Home" => "https://tg.pl/drab"
      }
    ]
  end
end
