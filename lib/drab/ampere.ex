defmodule Drab.Ampere do
  @moduledoc false

  # engine: Drab.Ampere.EExEngine
  def render_live(template, assigns \\ []) do
    EEx.eval_file(template, [assigns: assigns], engine: Drab.Ampere.EExEngine)
  end
end
