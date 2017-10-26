defmodule DrabTestApp.FakeCommander do
  @moduledoc false
  def fake_handler(_, _) do
    raise "fake handler should never be called from the browser"
  end
end
