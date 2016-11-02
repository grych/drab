defmodule Drab.Commander do
  @moduledoc """
  Enables Drab Commander on the module. Imports all Drab.Query functions.
  """

  defmacro __using__(options) do
    quote do
      import Drab.Query
      Module.put_attribute(__MODULE__, :__drab_opts__, unquote(options))

      unless Module.defines?(__MODULE__, {:__drab__, 0}) do
        def __drab__() do
          opts = Enum.into(@__drab_opts__, %{commander: __MODULE__})
          Map.merge(%Drab.Config{}, opts) 
        end
      end
    end
  end

end
