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
    path |> File.read!() |> EEx.compile_string(engine: Drab.Live.EExEngine, file: path, line: 1)
  end
end
