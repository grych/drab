defmodule Drab.Socket do
  @moduledoc """
  Drab operates on websockets. To enable it, you should inject the Drab.Channel into your Socket module 
  (by default it is `UserSocket` in `web/channels/user_socket.ex`):

      defmodule MyApp.UserSocket do
        use Phoenix.Socket
        use Drab.Socket
      end

  This creates a channel "__drab:*" used by all Drab operations.

  By default, Drab uses auto-generated socket with "/socket" path. In case of using different path, use config:

      config :drab, 
        socket: "/my/socket"

  """

  defmacro __using__(_options) do
    quote do
      channel "__drab:*", Drab.Channel

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

    end
  end

end
