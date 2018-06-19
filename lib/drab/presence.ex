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

  Please also ensure that there `main_phoenix_app` and `endpoint` for this app are configured
  correctly:

      config :drab, main_phoenix_app: :my_app_web, endpoint: MyAppWeb.Endpoint

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

  The ID may also be taken from Plug Session. For example, you have a `:current_user_id` stored in
  the session, you may want to use it as an id with `id` config option:

      config :drab, :presence, id: :current_user_id

  So this ID will become the key of the presence map:

      iex> Drab.Presence.list socket
      %{
        "42" => %{
          metas: [%{online_at: 1520417565, phx_ref: ...}]
        }
      }

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
        use Phoenix.Presence, otp_app: Drab.Config.app_name(), pubsub_server: Drab.Config.pubsub()

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
  # TODO: remove nowarn when Phx release new specs
  @dialyzer {:nowarn_function, init: 1}

  use Phoenix.Presence, otp_app: Drab.Config.app_name(), pubsub_server: Drab.Config.pubsub()

  @doc false
  @spec start(Phoenix.Socket.t(), String.t()) :: {:ok, binary()} | {:error, reason :: term()}
  def start(socket, topic) do
    client_id =
      Drab.Core.get_session(socket, Drab.Config.get(:presence, :id)) || Drab.Browser.id!(socket)

    case track(socket.channel_pid, topic, client_id, %{online_at: System.system_time(:seconds)}) do
      {:ok, reason} -> {:ok, reason}
      {:error, {:already_tracked, _, _, _} = reason} -> {:ok, reason}
      {:error, reason} -> raise inspect(reason)
    end
  end

  @doc false
  @spec stop(Phoenix.Socket.t(), String.t()) :: :ok
  def stop(socket, topic) do
    client_id =
      Drab.Core.get_session(socket, Drab.Config.get(:presence, :id)) || Drab.Browser.id!(socket)

    untrack(socket.channel_pid, topic, client_id)
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
