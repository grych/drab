defmodule Mix.Tasks.Drab.Gen.Commander do
  use Mix.Task
  
  @shortdoc "Generates a Drab Commander"

  @moduledoc """
  Generates a Drab commander.

      mix drab.gen.commander Name

  This will generate a module NameCommander in web/commanders, if and only if NameController is already present.
  """

  def run(args) do
    [module] = validate_args!(args)

    inf = Mix.Phoenix.inflect(module)
    module = web_module(inf)
    path = inf[:path]

    # Drab requires Phoenix, so I can use its brilliant helpers
    Mix.Phoenix.check_module_name_availability!(module <> "Commander")
    check_controller_existence!(path, module)

    copy_from paths(), "priv/templates/drab/", [module: module], [
      {:eex, "drab.gen.commander.ex.eex", "#{web_path()}/commanders/#{path}_commander.ex"}
    ]

    Mix.shell.info """

    Add the following line to your #{module}Controller:
        use Drab.Controller 
    """
  end

  defp check_controller_existence!(path, module) do
    controller_file = "#{web_path()}/controllers/#{path}_controller.ex"
    unless File.exists?(controller_file) do
      unless Mix.shell.yes?("Can't find corresponding #{module}Controller in #{controller_file}. Proceed? ") do
        Mix.raise "Aborted"
      end
    end
  end

  defp validate_args!(args) do
    unless length(args) == 1 do
      Mix.raise """
      mix drab.gen.commander expects module name:
          mix drab.gen.commander Name
      """
    end
    args
  end

  defp paths do
    [".", :drab]
  end

  defp web_module(inflected) do
    if phoenix12?() do
      inflected[:module]
    else
      "#{inflected[:web_module]}.#{inflected[:alias]}"
    end
  end

  defp web_path() do
    if phoenix12?() do
      "web"
    else
      #TODO: read web path from Phoenix View :root
      "lib/#{Drab.Config.app_name()}_web"
    end
  end

  defp phoenix12?(), do: Regex.match?(~r/^1.2/, Application.spec(:phoenix, :vsn) |> to_string())

  if Regex.match?(~r/^1.2/, Application.spec(:phoenix, :vsn) |> to_string()) do
    defp copy_from(paths, source_path, binding, mapping) do
      Mix.Phoenix.copy_from paths, source_path, "", binding, mapping
    end
  else
    defp copy_from(paths, source_path, binding, mapping) do
      Mix.Phoenix.copy_from paths, source_path, binding, mapping
    end
  end

end
