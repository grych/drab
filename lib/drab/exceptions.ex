defmodule Drab.JSExecutionError do
  @moduledoc """
  Raised when the browser encounters a JS error or the timeout for the current operation.
  """
  defexception message: nil
end

