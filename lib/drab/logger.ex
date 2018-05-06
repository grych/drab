defmodule Drab.Logger do
  @moduledoc false
  require Logger
  use Drab.Commander

  public(:error)

  @spec error(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  def error(socket, payload) do
    # report error coming from the browser
    Logger.error("""
    Browser reports: #{payload["message"]}
    """)

    socket
  end
end
