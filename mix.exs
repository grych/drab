defmodule Drab.Mixfile do
  use Mix.Project
  @version "0.0.17"

  def project do
    [app: :drab,
     version: @version,
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     # docs: [source_ref: "v#{@version}", main: "Drab",
     #        source_url: "https://github.com/grych/drab"]]
     deps: deps(),
     description: description(),
     package: package()
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
     {:phoenix, "~> 1.2"},
     {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description() do
    """
    The plugin to Phoenix Framework to query and manipulate browser DOM objects on the server (Elixir) side.
    """
  end

  defp package() do
    [
      name: :drab,
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Tomek Gryszkiewicz"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/grych/drab", "Docs" => "https://tg.pl/drab/docs", "Home" => "https://tg.pl/drab"}
    ]
  end

end
