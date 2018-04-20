defmodule DrabModule do
  # TODO: docs, describe how to write own drab module
  @moduledoc false

  # Drab behaviour
  # All Drab Modules must provide a list of prerequisite modules (except Drab.Core, which is loaded
  # by defaut),
  # as well as the list of the Javascripts to render
  @callback prerequisites() :: list
  @callback js_templates() :: list
  @callback transform_payload(payload :: map, state :: Drab.t()) :: map
  @callback transform_socket(socket :: Phoenix.Socket.t(), payload :: map, state :: Drab.t()) ::
              map

  defmacro __using__(_opts) do
    quote do
      @behaviour DrabModule

      @impl true
      def prerequisites(), do: []
      @impl true
      def js_templates(), do: []
      @impl true
      def transform_payload(payload, _state), do: payload
      @impl true
      def transform_socket(socket, _payload, _state), do: socket

      defoverridable prerequisites: 0, js_templates: 0, transform_payload: 2, transform_socket: 3
    end
  end

  @doc false
  @spec all_modules_for(list) :: list
  def all_modules_for(modules) do
    modules = modules |> prereqs_for() |> List.flatten() |> Enum.reverse()
    Enum.uniq(modules ++ [Drab.Core])
  end

  @doc false
  @spec all_templates_for(list) :: list
  def all_templates_for(modules) do
    modules
    |> all_modules_for()
    |> Enum.map(fn mod -> mod.js_templates end)
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec prereqs_for(atom | list) :: list
  defp prereqs_for(module) when is_atom(module) do
    [module | prereqs_for(module.prerequisites())]
  end

  defp prereqs_for(modules) when is_list(modules) do
    Enum.map(modules, &prereqs_for/1)
  end
end
