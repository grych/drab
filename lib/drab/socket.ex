defmodule Drab.Socket do
  @moduledoc """
  Drab operates on websockets. To enable it, you need to tell your application's socket module to
  use Drab. For this, you will need to modify the socket module (by default it is `UserSocket` in `web/channels/user_socket.ex`).

  There are two ways to archive this: let the Drab do the stuff, or provide your own `connect/2`
  callback. First method is good for the application without socket level authentication. Second
  one is more elaborate, but you could provide check or socket modification while connect.

  ## Method 1: Inject the code with `use Drab.Socket`
  The straightforward one, you only need to inject the `Drab.Socket` module into your Socket
  (by default it is `UserSocket` in `web/channels/user_socket.ex`):

      defmodule MyApp.UserSocket do
        use Phoenix.Socket
        use Drab.Socket
        ...
      end

  This creates a channel "__drab:*" used by all Drab operations.

  You may create your own channels inside a Drab Socket, but you *can't provide your own `connect`
  callback*. Drab Client (on JS side) always connects when the page loads and Drab's built-in
  `connect` callback intercepts this call. If you want to pass the parameters to the Channel, you
  may do it in `Drab.Client.run/2`, they will appear in Socket's assigns. Please visit
  `Drab.Client` to learn more.

  This method is supposed to be used with `Drab.Client.run/2` JS code generator.

  ## Method 2: Use your own `connect/2` callback
  In this case, you **must not** add `use Drab.Socket` into your `UserSocket`. Instead, use
  the following code snippet:

      defmodule MyApp.UserSocket do
        use Phoenix.Socket

        channel "__drab:*", Drab.Channel

        # For Phoenix <= 1.3
        def connect(params, socket) do
          Drab.Socket.verify(socket, params)
        end

        # For Phoenix 1.4
        def connect(params, socket, _connect_info) do
          Drab.Socket.verify(socket, params)
        end
      end

  `Drab.Socket.verify/2` returns tuple `{:ok, socket}` or `:error`, where `socket` is modified
  with Drab internal assigns, as well as with the additional assigns you may pass to
  `Drab.Client.generate/2`.

  This method is supposed to be used with `Drab.Client.generate/2` JS code generator, followed by
  the javascript `Drab.connect({token: ...})`, or with `Drab.Client.run/2` with additional assigns.

  The following example adds `"auth_token" => "forty-two"` key-value pair to `params` in the
  `connect/2` callback:

      ### app.html.eex
      <%= Drab.Client.generate(@conn) %>
      <script>
        if (window.Drab) Drab.connect({auth_token: "forty-two"});
      </script>

  Please do not forget to verify Drab token, even when using external authorization library:

      ### user_socket.ex
      def connect(%{"auth_token" => auth_token} = params, socket) do
        case MyAuthLib.authorize(auth_token) do
          {:ok, authorized_socket} -> Drab.Socket.verify(authorized_socket, params)
          _ -> :error
        end
      end
      def connect(_, _), do: error


  Please visit `Drab.Client` for more detailed information.

  ## Configuration Options
  By default, Drab uses "/socket" as a path. In case of using different one, configure it with:

      config :drab, MyAppWeb.Endpoint,
        socket: "/my/socket"

  This entry must correspond with the entry in your endpoint.ex.
  """

  defmacro __using__(_options) do
    quote do
      channel("__drab:*", Drab.Channel)

      def connect(%{"__drab_return" => _} = token, socket) do
        Drab.Socket.verify(socket, token)
      end

      def connect(%{"__drab_return" => _} = token, socket, _) do
        connect(token, socket)
      end
    end
  end

  @doc """
  Verifies the Drab token.

  Returns:
  * `{:ok, socket}` on success, where the socket is modified with internal Drab assigns, as well as
     with additinal user's assigns passed by `Drab.Client.generate/2` or `Drab.Client.run/2`
  * `:error`, when token is invalid

  To be used with custom `connect/2` callbacks.
  """
  @spec verify(Phoenix.Socket.t(), map) :: {:ok, term} | :error
  def verify(socket, %{
        "__drab_return" => controller_and_action_token,
        "__client_lib_version" => client_lib_version,
        "__client_id" => client_id
      }) do
    case Drab.Client.api_version() do
      ^client_lib_version ->
        case Phoenix.Token.verify(
               socket,
               "controller_and_action",
               controller_and_action_token,
               max_age: Drab.Config.get(socket.endpoint, :token_max_age)
             ) do
          {:ok,
           [
             controller: controller,
             commander: commander,
             view: view,
             action: action,
             assigns: assigns
           ]} ->
            own_plus_external_assigns = Map.merge(Enum.into(assigns, %{}), socket.assigns)

            socket_plus_external_assings = %Phoenix.Socket{
              socket
              | assigns: own_plus_external_assigns
            }

            {
              :ok,
              socket_plus_external_assings
              |> Phoenix.Socket.assign(:__controller, controller)
              |> Phoenix.Socket.assign(:__commander, commander)
              |> Phoenix.Socket.assign(:__view, view)
              |> Phoenix.Socket.assign(:__action, action)
              |> Phoenix.Socket.assign(:__client_id, client_id)
            }

          {:ok, _} ->
            :error

          {:error, _reason} ->
            :error
        end

      # wrong API version, user needs to reload page
      _ ->
        :error
    end
  end

  def verify(_, _) do
    :error
  end

  # TODO: use private, https://github.com/phoenixframework/phoenix/issues/2967
  # defp put_private(%Phoenix.Socket{private: private} = socket, key, value) when is_atom(key) do
  #   %{socket | private: Map.put(private, key, value)}
  # end
end
