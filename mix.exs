defmodule Drab.Mixfile do
  use Mix.Project
  @version "0.3.2"

  def project do
    [app: :drab,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps(),
     description: description(),
     package: package(),
     compilers: [:phoenix, :gettext] ++ Mix.compilers
   ]
  end

  # def application do
  #   [
  #     applications: [:logger],
  #   ]
  # end

  def application do
    [mod: {DrabTestApp, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev),  do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description() do
    """
    Plugin to the Phoenix Framework to query and manipulate User Interface in the browser directly from Elixir.
    """
  end

  defp package() do
    [
      name: :drab,
      # files: ["lib", "priv", "test", "mix.exs", "README*", "LICENSE*"],
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Tomek Gryszkiewicz"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/grych/drab", 
        "Docs with Examples" => "https://tg.pl/drab/docs", 
        "Home" => "https://tg.pl/drab"
      }
    ]
  end

end
