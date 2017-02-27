defmodule Drab.Socket do
  # @external_resouce Mix.Project.config[:config_path]
  @external_resource "/Users/grych/Dropbox/elixir/phoenix/drabrella/apps/drab_poc/config/config.exs"
  @moduledoc false
  IO.puts Mix.Project.config[:config_path]

  use Phoenix.Socket
  require Logger

  ## Channels
  channel "drab:*", Drab.Channel
  IO.puts "       ADD CHANNELS #{inspect Drab.config.additional_channels}"
  Drab.config.additional_channels |> Enum.map(fn {name, module} ->
    IO.puts "XXXXXx"
    IO.puts name
    IO.puts inspect(module)
    case name do
      "drab:" <> _ ->
        Logger.error """
        Channel name #{name} is restricted. This config entry for `additional_channels` will be ignored.
        """
      _ ->
        channel name, module
    end
  end)

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
