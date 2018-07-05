if Drab.Config.get(:presence) do
  defmodule Drab.Presence do
    @moduledoc """
    Conveniences for `Phoenix.Presence`.

    Provides Phoenix Presence module for Drab, along with some helper functions.

    ## Installation
    It is disabled by default, to enable it, add `:presence` to `config.exs`.

        config :drab, :presence, true

    Next, add `Drab.Presence` to your supervision tree in `lib/my_app_web.ex`:

        children = [
          ...
          Drab.Presence,
        ]

    Please also ensure that there `otp_app` and endpoint for this app are configured correctly:

        config :drab, MyAppWeb.Endpoint,
          otp_app: :my_app_web

    In multiple endpoint configuration, you need to specify which endpoint to use with
    `Drab.Presence`:

        config :drab, :presence, endpoint: MyAppWeb.Endpoint

    ## Usage
    When installed, system tracks the presence over every Drab topic, both static topics configured
    by `Drab.Commander.broadcasting/1` and runtime topics run by `Drab.Commander.subscribe/2`.
    The default ID of the presence list is a browser UUID (`Drab.Browser.id/1`):

        iex> Drab.Presence.list socket
        %{
          "2bd34ffc-b365-46a9-9479-474b628364ed" => %{
            metas: [%{online_at: 1520417565, phx_ref: ...}]
          }
        }

    The ID may also be taken from Plug Session or from the Drab Store. For example, you have
    a `:current_user_id` stored in the session, you may want to use it as an id with
    `id` config option:

        config :drab, :presence, id: [session: :current_user_id]

    So this ID will become the key of the presence map:

        iex> Drab.Presence.list socket
        %{
          "42" => %{
            metas: [%{online_at: 1520417565, phx_ref: ...}]
          }
        }

    Notice that system transforms the key value to the binary string.

    The similar would be with the Drab Store:

        config :drab, :presence, id: [store: :current_user_id]

    There is also a possibility to specify both store and session. In this case the order matters:
    if you put store first, it will take a value from the store, and it is not found, from session.

        config :drab, :presence, id: [store: :current_user_id, session: :current_user_id]
        config :drab, :presence, id: [session: :current_user_id, store: :current_user_id]

    ### Example
    Here we are going to show how to display number of connected users online. The solution is to
    broadcast every connect and disconnect using Commander's callbacks.
    Thus, in the commander:

        defmodule MyAppWeb.MyCommander
          use Drab.Commander
          import Drab.Presence

          broadcasting "global"
          onconnect :connected
          ondisconnect :disconnected

          def connected(socket) do
            broadcast_html socket, "#number_of_users", count_users(socket)
          end

          def disconnected(_store, _session) do
            topic = same_topic("global")
            broadcast_html topic, "#number_of_users", count_users(topic)
          end
        end

    Notice the difference between `connected` and `disconnected` callbacks. In the first case
    we could use the default topic derived from the `socket`, but after disconnect socket does not
    longer exists.

    ## Own Presence module
    You may also want to provide your own presence module, for example to override
    `Phoenix.Presence.fetch/2` function. In this case, add your module to `children` list and
    configure Drab to run it:

        config :drab, :presence, module: MyAppWeb.MyPresence

    You module must provide `start/2` function, which will be launched by Drab on the client connect,
    along with `stop/2`, which runs when user unsubscribe from the topic.

        defmodule MyAppWeb.MyPresence do
          use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub

          def start(socket, topic) do
            client_id = Drab.Browser.id!(socket)
            track(socket.channel_pid, topic, client_id, %{online_at: System.system_time(:seconds)})
          end

          def stop(socket, topic) do
            client_id = Drab.Browser.id!(socket)
            untrack(socket.channel_pid, topic, client_id)
          end
        end
    """

    # this is because of the wrong specs in Phx <=1.3.3
    @dialyzer {:nowarn_function, init: 1}

    use Phoenix.Presence,
      otp_app:
        Drab.Config.app_name(
          Drab.Config.get(:presence, :endpoint) || Drab.Config.default_endpoint()
        ),
      pubsub_server:
        Drab.Config.pubsub(
          Drab.Config.get(:presence, :endpoint) || Drab.Config.default_endpoint()
        )

    @doc false
    @spec start(Phoenix.Socket.t(), String.t()) :: {:ok, binary()} | {:error, reason :: term()}
    def start(socket, topic) do
      case track(socket.channel_pid, topic, client_id(socket), %{
             online_at: System.system_time(:seconds)
           }) do
        {:ok, reason} -> {:ok, reason}
        {:error, {:already_tracked, _, _, _} = reason} -> {:ok, reason}
        {:error, reason} -> raise inspect(reason)
      end
    end

    @doc false
    @spec stop(Phoenix.Socket.t(), String.t()) :: :ok
    def stop(socket, topic) do
      untrack(socket.channel_pid, topic, client_id(socket))
    end

    @spec client_id(Phoenix.Socket.t()) :: String.t() | no_return
    defp client_id(socket) do
      case Drab.Config.get(:presence, :id) do
        [store: store_key, session: session_key] ->
          Map.get(socket.assigns[:__store], store_key, nil) ||
            Drab.Core.get_session(socket, session_key)

        [session: session_key, store: store_key] ->
          Drab.Core.get_session(socket, session_key) ||
            Map.get(socket.assigns[:__store], store_key, nil)

        [session: session_key] ->
          Drab.Core.get_session(socket, session_key)

        [store: store_key] ->
          Map.get(socket.assigns[:__store], store_key, nil)

        session_key when is_atom(session_key) ->
          Drab.Core.get_session(socket, session_key)

        _ ->
          nil
      end || Drab.Browser.id!(socket)
    end

    @doc """
    Counts the number of connected unique users or browsers.
    """
    @spec count_users(Phoenix.Socket.t() | String.t()) :: integer
    def count_users(topic), do: Enum.count(list(topic))

    @doc """
    Returns the number of total connections to the topic.
    """
    @spec count_connections(Phoenix.Socket.t() | String.t()) :: integer
    def count_connections(topic) do
      for {_, %{metas: metas}} <- list(topic) do
        Enum.count(metas)
      end
      |> Enum.sum()
    end
  end
end
