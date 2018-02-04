defmodule Drab.JSExecutionError do
  @moduledoc """
  Raised when the browser encounters a JS error or the timeout for the current operation.
  """

  @doc false
  defexception message: "JavaScript error"
end
