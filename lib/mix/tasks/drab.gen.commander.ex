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

    binding = Mix.Phoenix.inflect(module)
    path    = binding[:path]

    # Drab requires Phoenix, so I can use its brilliant helpers
    Mix.Phoenix.check_module_name_availability!(binding[:module] <> "Commander")
    check_controller_existence!(path, binding[:module])

    Mix.Phoenix.copy_from paths(), "priv/templates/drab/", "", binding, [
      {:eex, "drab.gen.commander.ex.eex", "web/commanders/#{path}_commander.ex"}
    ]

    Mix.shell.info """

    Add the following line to your #{binding[:module]}Controller:
        use Drab.Controller 
    """
  end

  defp check_controller_existence!(path, module) do
    controller_file = "web/controllers/#{path}_controller.ex"
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
end
