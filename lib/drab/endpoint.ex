defmodule Drab.Endpoint do
  @moduledoc ~S"""
  To enable drab, use the following clause in your projects `lib/endpoint.ex`:

      use Drab.Endpoint
  """

  defmacro __using__(_options) do
    quote do
      socket Drab.config.socket, Drab.Socket
    end
  end
end
