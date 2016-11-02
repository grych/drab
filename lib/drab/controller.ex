defmodule Drab.Controller do
  @moduledoc """
  Turns on the Drab Commander on the pages controlled by this controller.

      use Drab.Controller, commander: CommanderModule
  
  options:

    * CommanderModule: commander module, defaults to similar name as controller, 
      eg. PageController becames PageCommander
  """
  
  defmacro __using__(options) do
    quote do
      Module.put_attribute(__MODULE__, :__drab_opts__, unquote(options))
      unless Module.defines?(__MODULE__, {:__drab__, 0}) do
        def __drab__() do
          # default commander is named as a controller
          controller_path = __MODULE__ |> Atom.to_string |> String.split(".")
          commander = controller_path |> List.last() |> String.replace("Controller", "Commander")
          module = controller_path |> List.replace_at(-1, commander) |> Module.concat

          Enum.into(@__drab_opts__, %{commander: module})
        end
      end
    end
  end
end
