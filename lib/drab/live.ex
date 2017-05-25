defmodule Drab.Live do
  @moduledoc false

  @behaviour Drab
  def prerequisites(), do: []
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  # engine: Drab.Live.EExEngine
  def render_live(template, assigns \\ []) do
    EEx.eval_file(template, [assigns: assigns], engine: Drab.Live.EExEngine)
  end
end
