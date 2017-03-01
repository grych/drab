defmodule Drab.Socket do
  @moduledoc """
  Drab operates on websockets. To enable it, you should inject the Drab.Channel into your Socket module 
  (by default it is `UserSocket` in `web/channels/user_socket.ex`):

      defmodule MyApp.UserSocket do
        use Phoenix.Socket
        use Drab.Socket
      end

  This creates a channel "__drab:*" used by all Drab operations.

  Drab uses the socket which is defined in your application `Endpoint` (default `lib/endpoint.ex`)
  By default, Drab uses "/socket" as a path. In case of using different one, configure it with:

      config :drab, 
        socket: "/my/socket"

  """

  defmacro __using__(_options) do
    quote do
      channel "__drab:*", Drab.Channel

      def connect(%{"__drab_return" => controller_and_action_token}, socket) do
        case Phoenix.Token.verify(socket, "controller_and_action", controller_and_action_token) do
          {:ok, [__controller: controller, __action: action, __assigns: assigns] = controller_and_action} -> 
            {:ok , socket 
                    |> assign(:__controller, controller)
                    |> assign(:__action, action)

            }
          {:error, _reason} -> :error
        end
      end

    end
  end

end
