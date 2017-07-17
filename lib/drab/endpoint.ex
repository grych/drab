# defmodule Drab.Endpoint do
#   @moduledoc ~S"""
#   Depreciated. To enable Drab, `use Drab.Socket` in your `UserSocket` module.
#   """

#   defmacro __using__(_options) do
#     IO.warn """
#     Injecting Drab into Endpoint is depreciated, Drab.Endpoint will be removed.
#     To enable Drab, `use Drab.Socket` in your `UserSocket` module.
#     """, Macro.Env.stacktrace(__ENV__)
#     quote do
#       # socket Drab.config.socket, Drab.Socket
#     end
#   end

# end
