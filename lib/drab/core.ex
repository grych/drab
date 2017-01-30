defmodule Drab.Core do
  @moduledoc ~S"""
  Drab Module with the basic communication from Server to the Browser. Does not require any libraries like jQuery,
  works on pure Phoenix.

      defmodule DrabPoc.JquerylessCommander do
        use Drab.Commander, modules: [] 

        def clicked(socket, payload) do
          socket |> console("You've sent me this: #{payload |> inspect}")
        end
      end

  See `Drab.Commander` for more info on Drab Modules.

  ## Running Elixir code from the Browser

  There is the Javascript method `Drab.launch_event()` in global `Drab` object, which allows you to run the Elixir
  function defined in the Commander. 

      Drab.launch_event(event_name, function_name, arguments_map)

  Arguments:
  * event_name(string) - name of the even which runs the function
  * function_name(string) - function name in corresponding Commander module
  * arguments_map(key/value object) - any arguments you want to pass to the Commander function

  Returns:
  * no return, does not wait for any answer

  """
  require Logger

  @doc """
  Synchronously executes the given javascript on the client side and returns value.
  """
  def execjs(socket, js) do
    # Phoenix.Channel.push(socket, "execjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.push(socket, self(), "execjs", js: js)

    receive do
      {:got_results_from_client, reply} ->
        reply
    end
  end

  @doc """
  Asynchronously broadcasts given javascript to all browsers displaying current page.
  """
  def broadcastjs(socket, js) do
    # Phoenix.Channel.broadcast(socket, "broadcastjs",  %{js: js, sender: tokenize(socket, self())})
    Drab.broadcast(socket, self(), "broadcastjs", js: js)
    socket
  end

  @doc """
  Sends the log to the browser console for debugging
  """
  def console(socket, log) do
    do_console(socket, log, &Drab.push/4)
    socket
  end

  @doc """
  Broadcasts the log to the browsers console for debugging
  """
  def console!(socket, log) do
    do_console(socket, log, &Drab.broadcast/4)
  end

  defp do_console(socket, log, push_or_broadcast_function) do
    push_or_broadcast_function.(socket, self(), "console",  log: log)
  end

  @doc false
  def encode_js(value), do: Poison.encode!(value)

  @doc """
  Returns the value of the Drab store represented by the given key.

      uid = get_store(socket, :user_id)
  """
  def get_store(socket, key) do
    socket.assigns.drab_store[key]
  end

  @doc """
  Returns the value of the Drab store represented by the given key or `default` when key not found

      counter = get_store(socket, :counter, 0)
  """
  def get_store(socket, key, default) do
    get_store(socket, key) || default
  end

  @doc """
  Returns the socket with the store key => value pair assigned. 

      put_store(socket, :counter, 1)
  """
  def put_store(socket, key, value) do
    store = socket.assigns.drab_store
    Phoenix.Socket.assign(socket, :drab_store, Map.merge(store, %{key => value}))
  end
end
