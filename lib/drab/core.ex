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

  There is the Javascript method `Drab.run_handler()` in global `Drab` object, which allows you to run the Elixir
  function defined in the Commander. 

      Drab.run_handler(event_name, function_name, argument)

  Arguments:
  * event_name(string) - name of the even which runs the function
  * function_name(string) - function name in corresponding Commander module
  * argument(anything) - any argument you want to pass to the Commander function

  Returns:
  * no return, does not wait for any answer

  Example:

      <button onclick="Drab.run_handler('click', 'clicked', {click: 'clickety-click'});">
        Clickme
      </button>

  The code above runs function named `clicked` in the corresponding Commander, with 
  the argument `%{"click" => "clickety-click}"`

  ## Store
  Analogically to Plug, Drab can store the values in its own session. To avoid confusion with the Plug Session session, 
  it is called a Store. You can use functions: `put_store/3` and `get_store/2` to read and write the values 
  in the Store. It works exactly the same way as a "normal", Phoenix session.

  * By default, Drab Store is kept in browser Local Storage. This means it is gone when you close the browser 
    or the tab. You may set up where to keep the data with drab_store_storage config entry.
  * Drab Store is not the Plug Session! This is a different entity. Anyway, you have an access 
    to the Plug Session (details below).
  * Drab Store is stored on the client side and it is signed, but - as the Plug Session cookie - not ciphered.

  ## Session
  Although Drab Store is a different entity than Plug Session (used in Controllers), there is a way 
  to access the Session. First, you need to whitelist the keys you wan to access in `access_session/1` macro 
  in the Commander (you may give it a list of atoms or a single atom). Whitelisting is due to security: 
  it is kept in Token, on the client side, and it is signed but not encrypted. 

      defmodule DrabPoc.PageCommander do
        use Drab.Commander

        onload :page_loaded, 
        access_session :drab_test

        def page_loaded(socket) do
          socket 
          |> update(:val, set: get_session(socket, :drab_test), on: "#show_session_test")
        end
      end

  There is not way to update session from Drab. Session is read-only.
  """
  require Logger

  @doc """
  Synchronously executes the given javascript on the client side and returns value.
  """
  def execjs(socket, js) do
    Drab.push(socket, self(), "execjs", js: js)

    receive do
      {:got_results_from_client, reply} ->
        reply
    # TODO: timeout
    end
  end

  @doc """
  Asynchronously broadcasts given javascript to all browsers displaying current page.
  """
  def broadcastjs(socket, js) do
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
    store = Drab.get_store(socket.assigns.__drab_pid)
    store[key]
    # store(socket)[key]
  end

  @doc """
  Returns the value of the Drab store represented by the given key or `default` when key not found

      counter = get_store(socket, :counter, 0)
  """
  def get_store(socket, key, default) do
    get_store(socket, key) || default
  end

  @doc """
  Saves the key => value in the Store. Returns unchanged socket. 

      put_store(socket, :counter, 1)
  """
  def put_store(socket, key, value) do
    store = store(socket) |> Map.merge(%{key => value})
    execjs(socket, "Drab.set_drab_store_token(\"#{tokenize_store(socket, store)}\")")

    # store the store in Drab server, to have it on terminate
    save_store(socket, store)

    socket
  end

  @doc false
  def save_store(socket, store) do
    Drab.update_store(socket.assigns.__drab_pid, store)
  end

  @doc """
  Returns the value of the Plug Session represented by the given key.

      counter = get_session(socket, :userid)

  You must explicit which session keys you want to access in `:access_session` option in `use Drab.Commander`.
  """
  def get_session(socket, key) do
    Drab.get_session(socket.assigns.__drab_pid)[key]
    # session(socket)[key]
  end

  @doc """
  Returns the value of the Plug Session represented by the given key or `default` when key not found

      counter = get_session(socket, :userid, 0)

  You must explicit which session keys you want to access in `:access_session` option in `use Drab.Commander`.
  """
  def get_session(socket, key, default) do
    get_session(socket, key) || default
  end

  @doc false
  def save_session(socket, session) do
    Drab.update_session(socket.assigns.__drab_pid, session)
  end

  @doc false
  def store(socket) do
    store_token = execjs(socket, "Drab.get_drab_store_token()")
    detokenize_store(socket, store_token)
    # GenServer.call(socket.assigns.__drab_pid, :get_store)
  end

  @doc false
  def session(socket) do
    store_token = execjs(socket, "Drab.drab_session_token")
    detokenize_store(socket, store_token)
  end

  def tokenize_store(socket, store) do
    Phoenix.Token.sign(socket, "drab_store_token",  store)
  end
 
  defp detokenize_store(_socket, drab_store_token) when drab_store_token == nil, do: %{} # empty store

  defp detokenize_store(socket, drab_store_token) do
    case Phoenix.Token.verify(socket, "drab_store_token", drab_store_token) do
      {:ok, drab_store} -> 
        drab_store
      {:error, reason} -> 
        raise "Can't verify the token: #{inspect(reason)}" # let it die    
    end
  end
end
