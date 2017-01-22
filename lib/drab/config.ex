defmodule Drab.Config do
  @moduledoc false

  # by default load Drab.Query and Drab.Call
  defstruct commander: nil, onload: nil, modules: [:query, :modal]
end
