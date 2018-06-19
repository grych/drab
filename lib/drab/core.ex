defmodule Drab.Core do
  @moduledoc ~S"""
  Drab module providing the base of communication between the browser and the server.

  `Drab.Core` defines the method to declare client-side events, which are handled server-side in
  the commander module. Also provides basic function for running JS code directly from Phoenix
  on the browser.

  ## Commander
  Commander is the module to keep your Drab functions (event handlers) in. See `Drab.Commander`
  for more info, and just for this part of docs let's assume you have the following one defined:

      defmodule DrabExample.PageCommander do
        use Drab.Commander, modules: []

        defhandler button_clicked(socket, payload) do
          socket |> console("You've sent me this: #{payload |> inspect}")
        end
      end

  ## Events
  Events are defined directly in the HTML by adding the `drab` attribute with the following pattern:

      <button drab='event_name#options:event_handler_function_name(argument)'>clickme</button>

  * `event_name` is the DOM event name, eg. "click", "blur"
  * `event_handler_function_name` - the name of the event handler function in the commander on
     the server side
  * `options` - optional, so far the only available option is "debounce(milliseconds)" for
     "keyup" event
  * `argument` - optional, additional argument to be passed to the event handler function as
     a third argument

  Example:

      <button drab='click:button_clicked'>clickme</button>

  Clicking above button launches `DrabExample.PageCommander.button_clicked/2` on the server side.

      <button drab='click:button_clicked(42)'>clickme</button>

  Clicking the button above launches `DrabExample.PageCommander.button_clicked/3` on the server
  side, with third argument of value 42. This is evaluated on the client side, so it could be
  any valid JS  expression:

      <button drab='click:button_clicked({the_answer: 42})'>
      <button drab='click:button_clicked(window.location)'>

  You may have multiple events defined for a DOM object, but the specific event may appear there
  only once (can't define two handlers for one event). Separate `event:handler` pairs with
  whitespaces:

      <button drab='click:button_clicked mouseover:prepare_button'>clickme</button>

  ### Shortcut form
  There are few shortcuts for the most popular events: `click`, `keyup`, `keydown`, `change`.
  For those events an attribute `drab-EVENTNAME` must be set. The following is an equivalent
  for the previous one:

      <button drab-click='button_clicked'>clickme</button>

  As above, there is a possibility to define multiple event handlers for one DOM object, but
  the only one handler for the event. The following form is valid:

      <button drab-click='button_clicked' drab-mouseover='prepare_button(42)'>clickme</button>

  But the next one is prohibited:

      <button drab-click='handler1' drab-click='handler2'>INCORRECT</button>

  In this case you may provide options with `drab-options` attribute, but only when you have
  the only one event defined.

  There is a possibility to configure the shortcut list:

      config :drab, :events_shorthands, ["click", "keyup", "blur"]

  Please keep this list short, as it affects client script performance.

  ### Long form [depreciated]
  You may also configure drab handler with `drab-event` and `drab-handler` combination, but
  please don't. This is coming from the ancient version of the software and will be removed
  in the stable release.

  #### Defining optional argument in multiple nodes with `drab-argument` attribute
  If you add `drab-argument` attribute to any tag, all children of this tag will use this as
  an optional attribute. Notice that the existing arguments are not overwritten, so this:

      <div drab-argument='42'>
        <button drab-click='button_clicked'>
        <button drab-click='button_clicked(43)'>
      </div>

  is the equivalent to:

      <button drab-click='button_clicked(42)'>
      <button drab-click='button_clicked(43)'>

  ### Handling event in any commander (Shared Commander)
  By default Drab runs the event handler in the commander module corresponding to the controller,
  which rendered the current page. But it is possible to choose the module by simply provide
  the full path to the commander:

      <button drab-click='MyAppWeb.MyCommander.button_clicked'>clickme</button>

  Notice that the module must be a commander module, ie. it must be marked with
  `use Drab.Commander`, and the function must be marked as public with `Drab.Commander.public/1`
  macro.

  ### Form values

  If the sender object is inside a `<form>` tag, it sends the "form" map, which contains values
  of all the inputs found withing the form. Keys of that map are "name" attribute of the input or,
  if not found, an "id" attribute. If neither "name" or "id" is given, the value of the form is
  not included.

  ## Running Elixir code from the Browser

  There is the Javascript method
  [`Drab.exec_elixir()`](Drab.Client.html#module-drab-exec_elixir-elixir_function_name-argument)
  in the global `Drab` object, which allows you to run the Elixir function defined in the Commander.

  ## Store

  Analogically to Plug, Drab can store the values in its own session. To avoid confusion with
  the Plug Session session, it is called a Store. You can use functions: `put_store/3` and
  `get_store/2` to read and write the values in the Store. It works exactly the same way as
  a "normal", Phoenix session.

  * By default, Drab Store is kept in browser Local Storage. This means it is gone when you close
    the browser or the tab. You may set up where to keep the data with `drab_store_storage`
    config entry, see Drab.Config
  * Drab Store is not the Plug Session! This is a different entity. Anyway, you have an access
    to the Plug Session (details below).
  * Drab Store is stored on the client side and it is signed, but - as the Plug Session cookie -
    not ciphered.

  ## Session

  Although Drab Store is a different entity than Plug Session (used in Controllers), there is a way
  to access the Session. First, you need to whitelist the keys you want to access in
  `access_session/1` macro in the Commander (you may give it a list of atoms or a single atom).
  Whitelisting is due to security: it is kept in Token, on the client side, and it is signed
  but not encrypted.

      defmodule DrabPoc.PageCommander do
        use Drab.Commander

        onload :page_loaded,
        access_session :drab_test

        def page_loaded(socket) do
          socket
          |> update(:val, set: get_session(socket, :drab_test), on: "#show_session_test")
        end
      end

  There is no way to update the session from Drab. Session is read-only.

  ## Broadcasting
  Normally Drab operates on the user interface of the browser which generared the event, but
  you may use it for broadcasting changes to all connected browsers. Drab uses a *topic*
  for distinguishing browsers, which are allowed to receive the change.

  Broadcasting function receives `socket` or `topic` as the first argument. If `socket` is used,
  function derives the `topic` from the commander configuration. See
  `Drab.Commander.broadcasting/1` to learn how to configure the broadcasting options. It is also
  possible to subscribe to the external topic in a runtime, using `Drab.Commander.subscribe/2`.

  Broadcasting functions may be launched without the `socket` given. In this case, you need
  to define it manually, using helper functions: `Drab.Core.same_path/1`, `Drab.Core.same_topic/1`
  and `Drab.Core.same_controller/1`. See `broadcast_js/3` for more.

  List of broadcasting functions:
    * `Drab.Core`:
      * `Drab.Core.broadcast_js/3`
      * `Drab.Core.broadcast_js!/3`
    * `Drab.Live`:
      * `Drab.Live.broadcast_poke/2`
    * `Drab.Element`:
      * `Drab.Element.broadcast_insert/4`
      * `Drab.Element.broadcast_prop/3`
    * `Drab.Query`:
      * `Drab.Query.delete!/2`
      * `Drab.Query.execute/2`, `Drab.Query.execute/3`
      * `Drab.Query.insert!/2`, `Drab.Query.insert!/3`
      * `Drab.Query.update!/2`, `Drab.Query.update!/3`
  """
  require Logger
  use DrabModule

  @typedoc "Returned status of all Core operations"
  @type status :: :ok | :error | :timeout

  @typedoc "Types returned from the browser"
  @type return :: String.t() | map | float | integer | list

  @typedoc "Return value of `exec_js/2`"
  @type result :: {status, return | :disconnected | :timeout}

  @typedoc "Return value of `broadcast_js/2`"
  @type bcast_result :: {:ok, term} | {:error, term}

  @typedoc "Subject for broadcasting"
  @type subject :: Phoenix.Socket.t() | String.t() | list

  @impl true
  def js_templates(), do: ["drab.core.js", "drab.events.js"]

  @impl true
  def transform_payload(payload, _state) do
    case payload["form"] do
      nil -> payload
      form -> Map.put_new(payload, :params, normalize_params(form))
    end
  end

  @doc false
  @spec normalize_params(map) :: map
  def normalize_params(params) do
    params |> Plug.Conn.Query.encode() |> Plug.Conn.Query.decode()
  end

  @doc """
  Synchronously executes the given javascript on the client side.

  Returns tuple `{status, return_value}`, where status could be `:ok`, `:error` or `:timeout`,
  and return value contains the output computed by the Javascript or the error message.

  ### Options

  * `timeout` in milliseconds

  ### Examples

      iex> socket |> exec_js("2 + 2")
      {:ok, 4}

      iex> socket |> exec_js("not_existing_function()")
      {:error, "not_existing_function is not defined"}

      iex> socket |> exec_js("for(i=0; i<1000000000; i++) {}")
      {:timeout, "timed out after 5000 ms."}

      iex> socket |> exec_js("alert('hello from IEx!')", timeout: 500)
      {:timeout, "timed out after 500 ms."}

  """
  @spec exec_js(Phoenix.Socket.t(), String.t(), Keyword.t()) :: result
  def exec_js(socket, js, options \\ []) do
    Drab.push_and_wait_for_response(socket, self(), "execjs", [js: js], options)
  end

  @doc """
  Exception raising version of `exec_js/2`

  ### Examples

        iex> socket |> exec_js!("2 + 2")
        4

        iex> socket |> exec_js!("nonexistent")
        ** (Drab.JSExecutionError) nonexistent is not defined
            (drab) lib/drab/core.ex:100: Drab.Core.exec_js!/2

        iex> socket |> exec_js!("for(i=0; i<1000000000; i++) {}")
        ** (Drab.JSExecutionError) timed out after 5000 ms.
            (drab) lib/drab/core.ex:100: Drab.Core.exec_js!/2

        iex> socket |> exec_js!("for(i=0; i<10000000; i++) {}", timeout: 1000)
        ** (Drab.JSExecutionError) timed out after 1000 ms.
            lib/drab/core.ex:114: Drab.Core.exec_js!/3

  """
  @spec exec_js!(Phoenix.Socket.t(), String.t(), Keyword.t()) :: return | no_return
  def exec_js!(socket, js, options \\ []) do
    case exec_js(socket, js, options) do
      {:ok, result} -> result
      {:error, :disconnected} -> raise Drab.ConnectionError
      {_, message} -> raise Drab.JSExecutionError, message: message
    end
  end

  @doc """
  Asynchronously executes the javascript on all the browsers listening on the given subject.

  The subject is derived from the first argument, which could be:

  * socket - in this case broadcasting option is derived from the setup in the commander.
    See `Drab.Commander.broadcasting/1` for the broadcasting options

  * same_path(string) - sends the JS to browsers sharing (and configured as listening to same_path
    in `Drab.Commander.broadcasting/1`) the same url

  * same_commander(atom) - broadcast goes to all browsers configured with :same_commander

  * same_topic(string) - broadcast goes to all browsers listening to this topic; notice: this
    is internal Drab topic, not a Phoenix Socket topic

  First argument may be a list of the above.

  The second argument is a JavaScript string.

  See `Drab.Commander.broadcasting/1` to find out how to change the listen subject.

      iex> Drab.Core.broadcast_js(socket, "alert('Broadcasted!')")
      {:ok, :broadcasted}
      iex> Drab.Core.broadcast_js(same_path("/drab/live"), "alert('Broadcasted!')")
      {:ok, :broadcasted}
      iex> Drab.Core.broadcast_js(same_controller(MyApp.LiveController), "alert('Broadcasted!')")
      {:ok, :broadcasted}
      iex> Drab.Core.broadcast_js(same_topic("my_topic"), "alert('Broadcasted!')")
      {:ok, :broadcasted}
      iex> Drab.Core.broadcast_js([same_topic("my_topic"), same_path("/drab/live")],
      "alert('Broadcasted!')")
      {:ok, :broadcasted}

  Returns `{:ok, :broadcasted}`
  """
  @spec broadcast_js(subject, String.t(), Keyword.t()) :: bcast_result
  def broadcast_js(subject, js, _options \\ []) do
    ret = Drab.broadcast(subject, self(), "broadcastjs", js: js)
    {ret, :broadcasted}
  end

  @doc """
  Bang version of `Drab.Core.broadcast_js/3`

  Returns subject.
  """
  @spec broadcast_js!(subject, String.t(), Keyword.t()) :: return
  def broadcast_js!(subject, js, _options \\ []) do
    Deppie.warn("Drab.Core.broadcast_js!/2 is depreciated, please use broadcast_js/2 instead")
    Drab.broadcast(subject, self(), "broadcastjs", js: js)
    subject
  end

  @doc """
  Helper for broadcasting functions, returns topic for a given URL path.

      iex> same_path("/test/live")
      "__drab:same_path:/test/live"
  """
  @spec same_path(String.t()) :: String.t()
  def same_path(url), do: "__drab:same_path:#{url}"

  @doc """
  Helper for broadcasting functions, returns topic for a given controller.

      iex> same_controller(DrabTestApp.LiveController)
      "__drab:controller:Elixir.DrabTestApp.LiveController"
  """
  @spec same_controller(String.t() | atom) :: String.t()
  def same_controller(controller), do: "__drab:controller:#{controller}"

  @doc """
  Helper for broadcasting functions, returns topic for a given controller and action.

      iex> same_action(DrabTestApp.LiveController, :index)
      "controller:Elixir.DrabTestApp.LiveController#index"
  """
  @spec same_action(String.t() | atom, String.t() | atom) :: String.t()
  def same_action(controller, action), do: "__drab:action:#{controller}##{action}"

  @doc """
  Helper for broadcasting functions, returns topic for a given topic string.

  Drab broadcasting topics are different from Phoenix topic - they begin with "__drab:". This is
  because you can share Drab socket with you own one.

      iex> same_topic("mytopic")
      "__drab:mytopic"
  """
  @spec same_topic(String.t()) :: String.t()
  def same_topic(topic), do: "__drab:#{topic}"

  @doc false
  @spec encode_js(term) :: String.t() | no_return
  def encode_js(value), do: Jason.encode!(value)

  @doc false
  @spec decode_js(iodata) :: term
  def decode_js(value) do
    case Jason.decode(value) do
      {:ok, v} -> v
      _ -> value
    end
  end

  @doc """
  Returns the value of the Drab store represented by the given key.

      uid = get_store(socket, :user_id)
  """
  @spec get_store(Phoenix.Socket.t(), atom) :: term
  def get_store(socket, key) do
    store = Drab.get_store(Drab.pid(socket))
    store[key]
    # store(socket)[key]
  end

  @doc """
  Returns the value of the Drab store represented by the given key or `default` when key not found

      counter = get_store(socket, :counter, 0)
  """
  @spec get_store(Phoenix.Socket.t(), atom, term) :: term
  def get_store(socket, key, default) do
    get_store(socket, key) || default
  end

  @doc """
  Saves the key => value in the Store. Returns unchanged socket.

      put_store(socket, :counter, 1)
  """
  @spec put_store(Phoenix.Socket.t(), atom, term) :: Phoenix.Socket.t()
  def put_store(socket, key, value) do
    store = socket |> store() |> Map.merge(%{key => value})
    {:ok, _} = exec_js(socket, "Drab.set_drab_store_token(\"#{tokenize_store(socket, store)}\")")

    # store the store in Drab server, to have it on terminate
    save_store(socket, store)

    socket
  end

  @doc false
  @spec save_store(Phoenix.Socket.t(), map) :: :ok
  def save_store(socket, store) do
    # TODO: too complicated, too many functions
    Drab.set_store(Drab.pid(socket), store)
  end

  @doc false
  @spec save_socket(Phoenix.Socket.t()) :: :ok
  def save_socket(socket) do
    Drab.set_socket(Drab.pid(socket), socket)
  end

  @doc """
  Returns the value of the Plug Session represented by the given key.

      counter = get_session(socket, :userid)

  You must explicit which session keys you want to access in `:access_session` option in
  `use Drab.Commander` or globally, in `config.exs`:

      config :drab, :access_session, [:user_id]
  """
  @spec get_session(Phoenix.Socket.t(), atom) :: term
  def get_session(socket, key) do
    socket.assigns[:__session] && socket.assigns[:__session][key]
  end

  @doc """
  Returns the value of the Plug Session represented by the given key or `default`,
   when key not found.

      counter = get_session(socket, :userid, 0)

  See also `get_session/2`.
  """
  @spec get_session(Phoenix.Socket.t(), atom, term) :: term
  def get_session(socket, key, default) do
    get_session(socket, key) || default
  end

  @doc false
  @spec store(Phoenix.Socket.t()) :: map
  def store(socket) do
    {:ok, store_token} = exec_js(socket, "Drab.get_drab_store_token()")
    detokenize_store(socket, store_token)
  end

  @doc false
  @spec tokenize_store(Phoenix.Socket.t() | Plug.Conn.t(), map) :: String.t()
  def tokenize_store(socket, store) do
    Drab.tokenize(socket, store, "drab_store_token")
  end

  @doc false
  @spec detokenize_store(Phoenix.Socket.t() | Plug.Conn.t(), String.t()) :: map
  # empty store
  def detokenize_store(_socket, drab_store_token) when drab_store_token == nil, do: %{}

  def detokenize_store(socket, drab_store_token) do
    # we just ignore wrong token and defauklt the store to %{}
    # this is because it is read on connect, and raising here would cause infinite reconnects
    case Phoenix.Token.verify(socket, "drab_store_token", drab_store_token, max_age: 86_400) do
      {:ok, drab_store} ->
        drab_store

      {:error, _reason} ->
        %{}
    end
  end

  @doc """
  Returns the selector of object, which triggered the event. To be used only in event handlers.

      def button_clicked(socket, sender) do
        set_prop socket, this(sender), innerText: "already clicked"
        set_prop socket, this(sender), disabled: true
      end
  """
  @spec this(map) :: String.t()
  def this(sender) do
    "[drab-id=#{Drab.Core.encode_js(sender["drab_id"])}]"
  end

  @doc """
  Like `this/1`, but returns selector of the object ID.

      def button_clicked(socket, sender) do
        socket |> update!(:text, set: "alread clicked", on: this!(sender))
        socket |> update!(attr: "disabled", set: true, on: this!(sender))
      end

  Raises exception when being used on the object without an ID.
  """
  @spec this!(map) :: String.t()
  def this!(sender) do
    id = sender["id"]

    unless id,
      do:
        raise(ArgumentError, """
        Try to use Drab.Core.this!/1 on DOM object without an ID:
        #{inspect(sender)}
        """)

    "##{id}"
  end

  @doc """
  Returns the unique selector of the DOM object, which represents the shared commander of
  the event triggerer.

  In case the even was triggered outside the Shared Commander, returns "" (empty string).

  To be used only in event handlers. Allows to create reusable Drab components.

      <div drab-commander="DrabTestApp.Shared1Commander">
        <div class="spaceholder1">Nothing</div>
        <button drab-click="button_clicked">Shared 1</button>
      </div>

      def button_clicked(socket, sender) do
        set_prop socket, this_commander(sender) <> " .spaceholder1", innerText: "changed"
      end
  """
  @spec this_commander(map) :: String.t()
  def this_commander(sender) do
    case sender["drab_commander_id"] do
      nil -> ""
      drab_commander_id -> "[drab-id=#{Drab.Core.encode_js(drab_commander_id)}]"
    end
  end
end
