defmodule Drab.JSExecutionError do
  @moduledoc """
  Raised when the browser encounters a JS error or the timeout for the current operation.
  """

  @doc false
  defexception message: "JavaScript error"

  @doc false
  @spec result_or_raise({:ok | :error, term}) :: term | no_return
  def result_or_raise({:ok, result}) do
    result
  end

  def result_or_raise({:error, description}) do
    raise Drab.JSExecutionError, message: to_string(description)
  end
end

defmodule Drab.ConnectionError do
  @moduledoc """
  Raised when function tries to query disconnected page.
  """

  @doc false
  defexception message: "Disconnected"
end

defmodule Drab.ConfigurationError do
  @moduledoc """
  Raised when misconfigured, for example trying to call not declared handler.
  """

  @doc false
  defexception message: "Misconfiguration"
end
