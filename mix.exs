defmodule Drab.Mixfile do
  use Mix.Project
  @version "0.2.2"

  def project do
    [app: :drab,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package()
   ]
  end

  def application do
    [
      applications: [:logger],
    ]
  end

  defp deps do
    [
     {:phoenix, "~> 1.2"},
     {:phoenix_html, "~> 2.6"},
     {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description() do
    """
    Plugin to the Phoenix Framework to query and manipulate browser DOM objects directly from Elixir.
    """
  end

  defp package() do
    [
      name: :drab,
      files: ["lib", "priv", "test", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Tomek Gryszkiewicz"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/grych/drab", 
        "Docs with Examples" => "https://tg.pl/drab/docs", 
        "Home" => "https://tg.pl/drab",
        "Docs" => "https://hexdocs.pm/drab"
      }
    ]
  end

end
