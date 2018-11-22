defmodule DrabTestApp.UserSocket do
  @moduledoc false

  use Phoenix.Socket
  # use Drab.Socket

  ## Channels
  # channel "room:*", DrabTestApp.RoomChannel

  ## Transports
  # transport(:websocket, Phoenix.Transports.WebSocket)
  # transport :longpoll, Phoenix.Transports.LongPoll

  channel("__drab:*", Drab.Channel)

  # def connect(params, socket) do
  #   Drab.Socket.verify(socket, params)
  # end

  def connect(%{"additional_token" => "something"} = params, socket) do
    Drab.Socket.verify(socket, params)
  end

  def connect(_, _) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     DrabTestApp.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
