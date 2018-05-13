defmodule Drab.Live.Engine do
  @moduledoc """
  Drab Template Engine, uses `Drab.Live.EExEngine` to compile templates.

  ### Installation
  Add to config:

      config :phoenix, :template_engines,
        drab: Drab.Live.Engine
  """
  alias Drab.Live.Safe
  @behaviour Phoenix.Template.Engine

  @impl true
  def compile(path, _name) do
    {:drab, %Safe{safe: safe, partial: partial}} =
      path |> File.read!() |> EEx.compile_string(engine: Drab.Live.EExEngine, file: path, line: 1)

    module = module_name(partial.hash)

    quoted =
      quote do
        @moduledoc false
        def partial(), do: unquote(Macro.escape(partial))
        def path(), do: partial().path
        def hash(), do: partial().hash
        def amperes(), do: partial().amperes
      end

    Module.create(module, quoted, Macro.Env.location(__ENV__))
    # if String.contains?(path, "live_engine_test.html") do
    #   IO.inspect partial
    # end
    {:safe, safe}
  end

  @spec module_name(String.t()) :: atom
  @doc false
  def module_name(hash) do
    Module.concat([Drab, Live, Template] ++ [String.capitalize(hash)])
  end
end
