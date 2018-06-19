defmodule Drab.Commander do
  require Logger

  @moduledoc """
  Drab Commander is a module to keep event handler functions.

  All the Drab functions (callbacks, event handlers) are placed in the module called `Commander`.
  Think about it as a controller for the living pages. Commanders should be placed in the
  `web/commanders` directory. They should have a corresponding controller, except the shared
  commander.

      defmodule DrabExample.PageCommander do
        use Drab.Commander

        defhandler click_button_handler(socket, sender) do
          ...
        end

        defhandler click_button_handler(socket, sender, optional) do
          ...
        end
      end

  Remember the difference: `controller` renders the page while `commander` works on the living
  stuff.

  ## Event handler functions
  Event handler is the function which process the request coming from the browser. It is done
  by running JS method `Drab.exec_elixir()` or from the DOM object with `drab` attribute.
  See `Drab.Core`, section Events, for a more description.

  The event handler function receives two or three parameters:
  * `socket` - the websocket used to communicate back to the page
  * `argument` or `sender` - an argument used in JS Drab.exec_elixir() method; when lauching
      an event via `drab=...` atrribute, it is a map which describes the sender object
  * `optional` - optional argument which may be defined directly in HTML, with `drab` attribute

  The `sender` map:

      %{
        "id"      => "sender object ID attribute",
        "name"    => "sender object 'name' attribute",
        "class"   => "sender object 'class' attribute",
        "text"    => "sender node 'text'",
        "html"    => "sender node 'html', result of running .html() on the node",
        "value"   => "sender object value",
        "data"    => "a map with sender object 'data-xxxx' attributes, where 'xxxx' are the keys",
        "event"   => "a map with choosen properties of `event` object"
        "drab_id" => "internal"
        "form"    => "a map of values of the sourrounding form"
        :params   => "a map of values of the sourrounding form, normalized to plug params"
      }

  The `event` map contains choosen properties of `event` object:

      altKey, data, key, keyCode, metaKey, shiftKey, ctrlKey, type, which,
      clientX, clientY, offsetX, offsetY, pageX, pageY, screenX, screenY

  Example:

      defhandler button_clicked(socket, sender) do
        # using Drab.Query
        socket |> update(:text, set: "clicked", on: this(sender))
      end

  `sender` may contain more fields, depending on the used Drab module. Refer to module
  documentation for more.

  Event handlers are running in their own processes, and they are linked to the channel process.
  This means that in case of disconnect or navigate away from the page, event handler processes
  are going to terminate. But please be aware that the process terminates just after the handler
  finish - and it terminates with the `:normal` state, which means all the linked processes are not
  going to stop. If you run infinite loop with `spawn_link` from the handler, and the handler
  finish normally, the loop will be unlinked and will stay with us forever.

  ### The only functions defined with `defhandler/2` or `public/1` are considered as handlers.
  For the safety, you must declare your function in the commander as a handler, using
  `defhandler/2` or `public/1` macro.

  ## Shared commanders
  By default, only the page rendered with the corresponding controller may run handler functions
  in the commander. But there is a possibility to create a shared commander, which is allowed
  to run from any page.

      defmodule DrabExample.SharedCommander do
        use Drab.Commander

        defhandler click_button_handler(socket, sender) do
          ...
        end
      end

  To call the shared commander function from page generated with the different controller, \
  you need to specify its full path".

      <button drab-click="DrabExample.SharedCommander.click_button_handler">Clickety</button>

  If you want to restrict shared commander for only specified controller, you must use
  `before_handler/1` callback with `controller/1` and `action/1` functions to check out,
  where the function is calling from.

  #### Define Shared Commander with `drab-commander` attribute on all children nodes
  If you add `drab-commander` attribute to any tag, all children of this tag will use Shared
  Commander defined in this tag. Notice it will not redefine nodes, which already has
  Shared Commander defined.

  Thus this:

      <div drab-commander="DrabExample.SharedCommander">
        <button drab-click="button1_clicked">1</button>
        <button drab-click="button2_clicked">1</button>
        <button drab-click="DrabExample.AnotherCommander.button3_clicked">1</button>
      </div>

  is equivalent of:

      <div>
        <button drab-click="DrabExample.SharedCommander.button1_clicked">1</button>
        <button drab-click="DrabExample.SharedCommander.button2_clicked">1</button>
        <button drab-click="DrabExample.AnotherCommander.button3_clicked">1</button>
      </div>

  See `Drab.Core.this_commander/1` to learn how to use this feature to create reusable Drab
  components.
  See also `Drab.Live` to learn how shared commanders works with living assigns.

  ## Callbacks

  Callbacks are an automatic events which are launched by the system. They are defined by the macro
  in the Commander module:

      defmodule DrabExample.PageCommander do
        use Drab.Commander

        onload :page_loaded
        onconnect :connected
        ondisconnect :disconnected

        before_handler :check_status
        after_handler  :clean_up, only: [:perform_long_process]

        def page_loaded(socket) do
          ...
        end

        def connected(socket) do
          ...
        end

        def connected(store, session) do
          # notice that this callback receives store and session, not socket
          # this is because socket is not available anymore (Channel is closed)
          ...
        end

        def check_status(socket, sender) do
          # return false or nil to prevent event handler to be launched
        end

        def clean_up(socket, dom_sender, handler_return_value) do
          # this callback gets return value of the corresponding event handler
        end
      end

  Notice that `oload`, `onconnect` and `ondisconnect` callbacks are not working with Shared
  Commander, they are only are invoked in the main one.

  #### `onconnect`
  Launched every time client browser connects to the server, including reconnects after server
  crash, network broken etc

  #### `onload`
  Launched only once after page loaded and connects to the server - exactly the same like
  `onconnect`, but launches only once, not after every reconnect

  #### `ondisconnect`
  Launched every time client browser disconnects from the server, it may be a network disconnect,
  closing the browser, navigate back. Disconnect callback receives Drab Store as an argument

  #### `before_handler`
  Runs before the event handler. If any of before callbacks return `false` or `nil`, corresponding
  event will not be launched. If there are more callbacks for specified event handler function,
  all are processed in order or appearance, then system checks if any of them returned false.

  Can be filtered by `:only` or `:except` options:

      before_handler :check_status, except: [:set_status]
      before_handler :check_status, only:   [:update_db]

  #### `after_handler`
  Runs after the event handler. Gets return value of the event handler function as a third argument.
  Can be filtered by `:only` or `:except` options, analogically to `before_handler`

  ### Using callbacks to check user permissions
  Callbacks are handy for security. You may retrieve controller name and action name from the
  socket with `controller/1` and `action/1`.

      before_handler :check_permissions
      def check_permissions(socket, _sender) do
        if controller(socket) == MyApp.MyController && action(socket) == :index do
          true
        else
          false
        end
      end

  ### Callbacks in Shared Commanders
  Handler-specific callbacks used in the Shared Commander works as expected - they are raised
  before or after the event handler function, and might work regionally (if they are called from
  inside the tag which has `drab-commander` attibute).

  However, page-specific callbacks (eg. `onload`) do not work regionally, as there is no specific
  object, which triggered the event. Thus, `Drab.Core.this_commander/1` can't be used there.

  ## Broadcasting options

  All Drab function may be broadcasted. By default, broadcasts are sent to browsers sharing the
  same page (the same url), but it could be override by `broadcasting/1` macro.

  ## Modules

  Drab is modular. You my choose which modules to use in the specific Commander by using `:module`
  option in `use Drab.Commander` directive.
  There is one required module, which is loaded always and can't be disabled: `Drab.Code`.
  By default, modules `Drab.Live` and `Drab.Element` are loaded. The following code:

      use Drab.Commander, modules: [Drab.Query]

  will override default modules, so only `Drab.Core` and `Drab.Query` will be available.

  Every module has its corresponding JS template, which is loaded only when module is enabled.

  ## Using templates

  Drab injects function `render_to_string/2` into your Commander. It is a shorthand for
  `Phoenix.View.render_to_string/3` - Drab automatically chooses the current View.

  ### Examples:

      buttons = render_to_string("waiter_example.html", [])

  ## Generate the Commander

  There is a mix task (`Mix.Tasks.Drab.Gen.Commander`) to generate skeleton of commander:

      mix drab.gen.commander Name

  See also `Drab.Controller`
  """

  defmacro __using__(options) do
    opts = Map.merge(%Drab.Commander.Config{}, Enum.into(options, %{}))

    modules =
      Enum.map(opts.modules, fn x ->
        case x do
          {:__aliases__, _, m} ->
            Module.concat(m)

          _ ->
            x
        end
      end)

    modules_to_import = DrabModule.all_modules_for(modules)

    quote do
      import unquote(__MODULE__)
      import Drab.Core

      o = Enum.into(unquote(options) || [], %{commander: __MODULE__})

      controller = Drab.Config.default_controller_for(__MODULE__)
      view = Drab.Config.default_view_for(__MODULE__)
      commander_config = %Drab.Commander.Config{controller: controller, view: view}

      @options Map.merge(commander_config, o)

      unquote do
        Enum.map(modules_to_import, fn module ->
          quote do
            import unquote(module)
          end
        end)
      end

      @doc """
      A shordhand for `Phoenix.View.render_to_string/3`. Injects the corresponding view.
      """
      def render_to_string(template) do
        render_to_string(template, [])
      end

      @doc """
      A shordhand for `Phoenix.View.render_to_string/3`. Injects the corresponding view.
      """
      def render_to_string(template, assigns) do
        view = __MODULE__.__drab__().view
        Phoenix.View.render_to_string(view, template, assigns)
      end

      @doc """
      A shordhand for `Phoenix.View.render_to_string/3`.
      """
      def render_to_string(view, template, assigns) do
        Phoenix.View.render_to_string(view, template, assigns)
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __drab__() do
        @options
      end
    end
  end

  @doc """
  Defines handler function.

  Handler is the Elixir function which is called from the browser, as a response for an event
  or using JS function `Drab.exec_elixir()`.

      defmodule MyApp.MyCommander
        use Drab.Commander

        defhandler handler1(socket, sender) do
          ...
        end
      end

  Trying to run non-handler function from the browser raises the exception on the Phoenix side.
  """
  defmacro defhandler(handler, do: block) do
    {handler_name, _, _} = handler

    quote do
      public(unquote(handler_name))
      def unquote(handler), do: unquote(block)
    end
  end

  @doc """
  Marks given function(s) as a handler(s). An alternative to `defhandler/2`.

      defmodule MyApp.MyCommander
        use Drab.Commander
        public [:handler1, :handler2]

        def handler1(socket, sender) do
          ...
        end
      end
  """
  defmacro public(handler) when is_atom(handler) do
    quote do
      public([unquote(handler)])
    end
  end

  defmacro public(handlers) when is_list(handlers) do
    quote do
      @options Map.put(
                 @options,
                 :public_handlers,
                 Enum.uniq(Map.get(@options, :public_handlers) ++ unquote(handlers))
               )
    end
  end

  Enum.each([:onload, :onconnect, :ondisconnect], fn macro_name ->
    @doc """
    Sets up the callback for #{macro_name}. Receives handler function name as an atom.

        #{macro_name} :event_handler_function

    See `Drab.Commander` summary for details.
    """
    defmacro unquote(macro_name)(event_handler) when is_atom(event_handler) do
      m = unquote(macro_name)

      quote bind_quoted: [m: m], unquote: true do
        Map.get(@options, m) &&
          raise CompileError, description: "Only one `#{inspect(m)}` definition is allowed"

        @options Map.put(@options, m, unquote(event_handler))
      end
    end

    defmacro unquote(macro_name)(unknown_argument) do
      raise CompileError,
        description: """
        Only atom is allowed in `#{unquote(macro_name)}`. Given: #{inspect(unknown_argument)}
        """
    end
  end)

  @doc """
  Drab may allow an access to specified Plug Session values. For this, you must whitelist the keys
  of the session map. Only this keys will be available to `Drab.Core.get_session/2`

      defmodule MyApp.MyCommander do
        user Drab.Commander

        access_session [:user_id, :counter]
      end

  Keys are whitelisted due to security reasons. Session token is stored on the client-side and
  it is signed, but not encrypted.
  """
  defmacro access_session(session_keys) when is_list(session_keys) do
    quote do
      access_sessions = Map.get(@options, :access_session)
      @options Map.put(@options, :access_session, access_sessions ++ unquote(session_keys))
    end
  end

  defmacro access_session(session_key) when is_atom(session_key) do
    quote do
      access_sessions = Map.get(@options, :access_session)
      @options Map.put(@options, :access_session, [unquote(session_key) | access_sessions])
    end
  end

  defmacro access_session(unknown_argument) do
    raise CompileError,
      description: """
      Only atom or list are allowed in `access_session`. Given: #{inspect(unknown_argument)}
      """
  end

  Enum.each([:before_handler, :after_handler], fn macro_name ->
    @doc """
    Sets up the callback for #{macro_name}. Receives handler function name as an atom and options.

        #{macro_name} :event_handler_function

    See `Drab.Commander` summary for details.
    """
    defmacro unquote(macro_name)(event_handler, filter \\ [])

    defmacro unquote(macro_name)(event_handler, filter) when is_atom(event_handler) do
      m = unquote(macro_name)

      quote bind_quoted: [m: m], unquote: true do
        handlers = Map.get(@options, m)
        @options Map.put(@options, m, handlers ++ [{unquote(event_handler), unquote(filter)}])
      end
    end

    defmacro unquote(macro_name)(unknown_argument, _filter) do
      raise CompileError,
        description: """
        only atom is allowed in `#{unquote(macro_name)}`, given: #{inspect(unknown_argument)}
        """
    end
  end)

  @broadcasts ~w(same_path same_controller same_action)a
  @doc """
  Set up broadcasting listen subject for the current commander.

  It is used by broadcasting functions, like `Drab.Element.broadcast_prop/3` or
  `Drab.Query.insert!/2`. When the browser connects to Drab page, it gets the broadcasting subject
  from the commander. Then, it will receive all the broadcasts coming to this subject.

  Default is `:same_path`

  Options:

  * `:same_path` (default) - broadcasts will go to the browsers rendering the same url
  * `:same_controller` - broadcasted message will be received by all browsers, which
    renders the page generated by the same controller
  * `:same_action` - the message will be received by the browsers, rendered with the
    same controller and action
  * `"topic"` - any topic you want to set, messages will go to the clients sharing this topic

  Please notice that Drab topic is not the same as Phoenix topic, it always begins with "__drab:"
  string. This is because you may share the socket between Drab and your own communication. Thus,
  always use `Drab.Core.same_topic/1` when broadcasting with Drab.

  See `Drab.Core.broadcast_js/2` for more.
  """
  defmacro broadcasting(subject) when is_atom(subject) and subject in @broadcasts do
    quote do
      broadcast_option = Map.get(@options, :broadcasting)
      @options Map.put(@options, :broadcasting, unquote(subject))
    end
  end

  defmacro broadcasting(subject) when is_binary(subject) do
    quote do
      broadcast_option = Map.get(@options, :broadcasting)
      @options Map.put(@options, :broadcasting, unquote(subject))
    end
  end

  defmacro broadcasting(unknown_argument) do
    raise CompileError,
      description: """
      invalid `broadcasting` option: #{inspect(unknown_argument)}.

      Available: :same_path, :same_action, :same_controller, "topic"
      """
  end

  @doc """
  Retrieves controller module, which generated the page the handler function is calling from,
  from the socket.
  """
  @spec controller(Phoenix.Socket.t()) :: atom
  def controller(socket) do
    socket.assigns.__controller
  end

  @doc """
  Retrieves action name in the controller, which rendered the page where handler is called from.
  """
  @spec action(Phoenix.Socket.t()) :: atom
  def action(socket) do
    socket.assigns.__action
  end

  @doc """
  Subscribe to the external topic for broadcasting.

  Default broadcasting topic is set in the compile time with `broadcasting/1` macro. Subscribing
  to the external topic may be done in the runtime.

  If you have `Drab.Presence` configured, subscription to the topic runs presence tracker on
  this topic.

  Please notice that you can't subscribe to the main topic (set with `broadcasting/1`).

  Returns `:ok` or `:duplicate` in case we are already subscribed to the external topic.

      iex> subscribe(socket, same_action(MyApp.MyController, :index))
      :ok
      iex> subscribe(socket, same_topic("product_#{42}"))
      :ok
      iex> subscribe(socket, same_topic("product_#{42}"))
      :duplicate
  """
  @spec subscribe(Phoenix.Socket.t(), Drab.Core.subject()) :: atom
  def subscribe(socket, topic) when is_binary(topic) do
    drab = Drab.pid(socket)
    topics = external_topics(socket)
    if topic in topics || topic == socket.topic do
      :duplicate
    else
      Drab.set_topics(drab, [topic | topics])
      if Drab.Config.get(:presence), do: Drab.Config.get(:presence, :module).start(socket, topic)
      Phoenix.Channel.broadcast socket, "subscribe", %{topic: topic}
    end
  end

  @doc """
  Unsubscribe from the external topic.

  Unsubscription from the topic stops the presence tracker on it (if `Drab.Presence` is running).

  Please notice that you can't unsubscribe from the main topic (set with `broadcasting/1`).

      iex> unsubscribe(socket, same_action(MyApp.MyController, :index))
      :ok
      iex> unsubscribe(socket, same_topic("product_#{42}"))
      :ok
  """
  @spec unsubscribe(Phoenix.Socket.t(), Drab.Core.subject()) :: atom
  def unsubscribe(socket, topic) when is_binary(topic) do
    if socket.assigns[:__broadcast_topic] do
      :error
    else
      drab = Drab.pid(socket)
      topics = external_topics(socket)
      Drab.set_topics(drab, List.delete(topics, topic))
      if Drab.Config.get(:presence), do: Drab.Config.get(:presence, :module).stop(socket, topic)
      Phoenix.Channel.broadcast socket, "unsubscribe", %{topic: topic}
    end
  end

  @doc """
  Returns list of external topics we subscribe.

  This list does not contain the main topic, as set with `broadcasting/1`.
  """
  @spec external_topics(Phoenix.Socket.t()) :: [String.t()]
  def external_topics(socket) do
    socket |> Drab.pid() |> Drab.get_topics()
  end

  @doc """
  Returns the current main broadcasting topic.
  """
  @spec topic(Phoenix.Socket.t()) :: String.t()
  def topic(socket), do: socket.topic
end
