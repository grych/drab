defmodule Drab.Socket do
  @moduledoc """
  Drab operates on websockets. To enable it, you should inject the Drab.Channel into your Socket module 
  (by default it is `UserSocket` in `web/channels/user_socket.ex`):

      defmodule MyApp.UserSocket do
        use Phoenix.Socket
        use Drab.Socket
      end

  This creates a channel "__drab:*" used by all Drab operations.

  You may create your own channels inside a Drab Socket, but you *can't provide your own `connect` callback*.
  Drab Client (on JS side) always connects at the page load and Drab's built-in `connect` callback will intercept
  this call. If you want to pass the parameters to the Channel, you may do it in `Drab.Client.js`, they 
  will appear in Socket's assigns. Please visit `Drab.Client` to learn more.

  Drab uses the socket which is defined in your application `Endpoint` (default `lib/endpoint.ex`)
  By default, Drab uses "/socket" as a path. In case of using different one, configure it with:

      config :drab, 
        socket: "/my/socket"

  """

  defmacro __using__(_options) do
    quote do
      channel "__drab:*", Drab.Channel

      def connect(%{"__drab_return" => controller_and_action_token}, socket) do
        case Phoenix.Token.verify(socket, "controller_and_action", controller_and_action_token, max_age: 86400) do
          {:ok, [__controller: controller, __action: action, __assigns: assigns] = controller_and_action} ->
            own_plus_external_assigns = Map.merge(Enum.into(assigns, %{}), socket.assigns)
            socket_plus_external_assings = %Phoenix.Socket{socket | assigns: own_plus_external_assigns}
            {:ok , socket_plus_external_assings 
                    |> assign(:__controller, controller)
                    |> assign(:__action, action)

            }
          {:error, _reason} -> :error
        end
      end
      def connect(%{"drab_return" => _controller_and_action_token}, socket) do
        # TODO: depreciate "drab_return", --> to be removed
        {:ok, socket}
      end

    end
  end

end
