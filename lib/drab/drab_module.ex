defmodule DrabModule do
  #TODO: docs
  @moduledoc false

  # Drab behaviour
  # All Drab Modules must provide a list of prerequisite modules (except Drab.Core, which is loaded by defaut),
  # as well as the list of the Javascripts to render
  @callback prerequisites() :: list
  @callback js_templates() :: list
  @callback transform_payload(payload :: list, state :: Drab.t) :: list
  @callback transform_socket(socket :: Phoenix.Socket.t, payload :: list, state :: Drab.t) :: list

  defmacro __using__(_opts) do
    quote do
      @behaviour DrabModule

      @doc false
      def prerequisites(), do: []
      @doc false
      def js_templates(),  do: []
      @doc false
      def transform_payload(payload, _state), do: payload
      @doc false
      def transform_socket(socket, _payload, _state), do: socket

      defoverridable [prerequisites: 0, js_templates: 0, transform_payload: 2, transform_socket: 3]
    end
  end

  @doc false
  def all_modules_for(modules) do
    modules = prereqs_for(modules) |> List.flatten() |> Enum.reverse()
    Enum.uniq(modules ++ [Drab.Core])
  end

  @doc false
  def all_templates_for(modules) do
    Enum.map(all_modules_for(modules), fn mod ->
      mod.js_templates
    end) |> List.flatten() |> Enum.uniq()
  end

  defp prereqs_for(module) when is_atom(module) do
    [module | prereqs_for(module.prerequisites())]
  end

  defp prereqs_for(modules) when is_list(modules) do
    Enum.map(modules, &prereqs_for/1)
  end

end
