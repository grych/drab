defmodule Drab.Socket do
  @moduledoc false

  use Phoenix.Socket
  require Logger

  ## Channels
  channel "drab:*", Drab.Channel
  # channel "mychannel:*", DrabPoc.Channel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  def connect(%{"drab_return" => controller_and_action_token}, socket) do
    case Phoenix.Token.verify(socket, "controller_and_action", controller_and_action_token) do
      {:ok, controller_and_action} -> 
        [controller, action] = String.split(controller_and_action, "#")
        {:ok , socket 
                |> assign(:controller, String.to_existing_atom(controller))
                |> assign(:action, String.to_existing_atom(action))
        }
      {:error, _reason} -> :error
    end
  end
  def connect(_params, _socket), do: :error

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     DrabPoc.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
