defmodule Drab.Live.Engine do
  @moduledoc """
  Drab Template Engine, uses `Drab.Live.EExEngine` to compile templates.

  ### Installation
  Add to config:

      config :phoenix, :template_engines,
        drab: Drab.Live.Engine
  """
  @behaviour Phoenix.Template.Engine

  @impl true
  def compile(path, _name) do
    if Process.get(:partial) == "gi3tgnrzg44tmnbs" do
      # path = "./_build/dev/lib/drab/ebin/"
      # {_, _, code, _} = defmodule Elixir.A do
      #   def a() do
      #     "aaaaxxx"
      #   end
      # end
      # File.write(path <> "Elixir.A.beam", code, [:write])
    end
    path |> File.read!() |> EEx.compile_string(engine: Drab.Live.EExEngine, file: path, line: 1)
  end
end
