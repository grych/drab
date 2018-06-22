defmodule Mix.Tasks.Drab.Gen.Commander do
  use Mix.Task

  @shortdoc "Generates a Drab Commander"

  @moduledoc """
  Generates a Drab commander.

      mix drab.gen.commander Name
      mix drab.gen.commander Context/Name

  This will generate a module NameCommander in web/commanders, if NameController is already present.
  """

  @impl true
  def run(args) do
    [module] = validate_args!(args)
    module = String.replace(module, ~r/Commander$/, "")

    inf = Mix.Phoenix.inflect(module)
    module = web_module(inf)
    path = inf[:path]

    # Drab requires Phoenix, so I can use its brilliant helpers
    Mix.Phoenix.check_module_name_availability!(module <> "Commander")
    raise_if_controller_does_not_exist(path, module)

    copy_from(paths(), "priv/templates/drab/", [module: module], [
      {:eex, "drab.gen.commander.ex.eex", "#{web_path()}/commanders/#{path}_commander.ex"}
    ])
  end

  defp raise_if_controller_does_not_exist(path, module) do
    controller_file = "#{web_path()}/controllers/#{path}_controller.ex"

    unless File.exists?(controller_file) do
      unless Mix.shell().yes?(
               "Can't find corresponding #{module}Controller in #{controller_file}. Proceed? "
             ) do
        Mix.raise("Aborted")
      end
    end
  end

  defp validate_args!(args) do
    unless length(args) == 1 do
      Mix.raise("""
      mix drab.gen.commander expects module name:
          mix drab.gen.commander Name
      """)
    end

    args
  end

  defp paths do
    [".", :drab]
  end

  @spec web_module(Keyword.t()) :: String.t()
  defp web_module(inflected) do
    if phoenix12?() do
      inflected[:module]
    else
      "#{inflected[:web_module]}.#{inflected[:scoped]}"
    end
  end

  @spec web_path() :: String.t()
  defp web_path() do
    if phoenix12?() do
      "web"
    else
      # TODO: read web path from Phoenix View :root
      app_name = Atom.to_string(Drab.Config.app_name())
      if app_name =~ ~r/.*_web$/i, do: "lib/#{app_name}", else: "lib/#{app_name}_web"
    end
  end

  defp phoenix12?(), do: Regex.match?(~r/^1.2/, to_string(Application.spec(:phoenix, :vsn)))

  if Regex.match?(~r/^1.2/, to_string(Application.spec(:phoenix, :vsn))) do
    defp copy_from(paths, source_path, binding, mapping) do
      Mix.Phoenix.copy_from(paths, source_path, "", binding, mapping)
    end
  else
    defp copy_from(paths, source_path, binding, mapping) do
      Mix.Phoenix.copy_from(paths, source_path, binding, mapping)
    end
  end
end
