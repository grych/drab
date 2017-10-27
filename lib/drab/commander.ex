defmodule Drab.Commander do
  require Logger

  @moduledoc """
  Drab Commander is a module to keep event handlers.

  All the Drab functions (callbacks, event handlers) are placed in the module called `Commander`. Think about
  it as a controller for the live pages. Commanders should be placed in `web/commanders` directory. Commander must
  have a corresponding controller.

      defmodule DrabExample.PageCommander do
        use Drab.Commander

        def click_button_handler(socket, dom_sender) do
          ...
        end
      end

  Remember the difference: `controller` renders the page while `commander` works on the live page.

  ## Event handler functions
  Event handler is the function which process the request coming from the browser. It is done by running JS method
  `Drab.exec_elixir()` or from the DOM object with `drab-handler` attribute. See `Drab.Core` for description.

  The event handler function receives two parameters:
  * `socket` - the websocket used to communicate back to the page
  * `argument` - an argument used in JS Drab.exec_elixir() method; when lauching an event via
    `drab-handler=function` atrribute, it is a map describing the sender object

  ### All public functions with arity of 2 in the commander module must be considered as handlers
  Please keep in mind that all public functions with arity of 2 in the commander may be called remotely from
  the browser.

  ## Shared commanders
  By default, only the page rendered with the corresponding controller may run handler functions in the
  commander. But there is a possibility to create a shared commander, which is allowed to run from any page.
  For this, you must mark the specific handlers as public, using `public/1` macro. Please notice it is your
  responsibility to make such functions safe.

  If you want to restrict shared controller for only specified controller, you must use `before_handler/1`
  callback with `controller/1` and `action/1` functions to check out where the function is calling from.

  ## Callbacks

  Callbacks are an automatic events which are launched by the system. They are defined by the macro in the
  Commander module:

      defmodule DrabExample.PageCommander do
        use Drab.Commander

        onload :page_loaded
        onconnect :connected
        ondisconnect :dosconnected

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

  #### `onconnect`
  Launched every time client browser connects to the server, including reconnects after server
  crash, network broken etc

  #### `onload`
  Launched only once after page loaded and connects to the server - exactly the same like `onconnect`,
  but launches only once, not after every reconnect

  #### `ondisconnect`
  Launched every time client browser disconnects from the server, it may be a network disconnect,
  closing the browser, navigate back. Disconnect callback receives Drab Store as an argument

  #### `before_handler`
  Runs before the event handler. If any of before callbacks return `false` or `nil`, corresponding event
  will not be launched. If there are more callbacks for specified event handler function, all are processed
  in order or appearance, then system checks if any of them returned false.

  Can be filtered by `:only` or `:except` options:

      before_handler :check_status, except: [:set_status]
      before_handler :check_status, only:   [:update_db]

  #### `after_handler`
  Runs after the event handler. Gets return value of the event handler function as a third argument.
  Can be filtered by `:only` or `:except` options, analogically to `before_handler`

  ### Using callbacks to check user permissions
  Callbacks are handy for security. You may retrieve controller name and action name from the socket with
  `controller/1` and `action/1`.

      before_handler :check_permissions
      def check_permissions(socket, _sender) do
        if controller(socket) == MyApp.MyController && action(socket) == :index do
          true
        else
          false
        end
      end

  ## Broadcasting options

  All Drab function may be broadcaster. By default, broadcasts are sent to browsers sharing the same page
  (the same url), but it could be override by `broadcasting/1` macro.

  ## Modules

  Drab is modular. You my choose which modules to use in the specific Commander by using `:module` option
  in `use Drab.Commander` directive.
  There is one required module, which is loaded always and can't be disabled: `Drab.Code`. By default, modules
  `Drab.Live` and `Drab.Element` are loaded. The following code:

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
    modules = Enum.map(opts.modules, fn x ->
      case x do
        # TODO: don't like this hack
        {:__aliases__, _, m} -> Module.concat(m)
        _ -> x
      end
    end)
    modules_to_import = DrabModule.all_modules_for(modules)

    quote do
      import unquote(__MODULE__)
      import Drab.Core

      o = Enum.into(unquote(options) || [], %{commander: __MODULE__})

      commander_path = __MODULE__ |> Atom.to_string() |> String.split(".")
      controller = commander_path |> List.last() |> String.replace("Commander", "Controller")
      controller = commander_path |> List.replace_at(-1, controller) |> Module.concat
      view = commander_path |> List.last() |> String.replace("Commander", "View")
      view = commander_path |> List.replace_at(-1, view) |> Module.concat
      commander_config = %Drab.Commander.Config{controller: controller, view: view}

      @options Map.merge(commander_config, o)

      unquote do
        # opts = Map.merge(%Drab.Commander.Config{}, Enum.into(options, %{}))
        modules_to_import |> Enum.map(fn module ->
          quote do
            import unquote(module)
          end
        end)
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
  Make handler function public, so it can be called from any page.

  This allow you to create a shared commanders

      defmodule MyApp.MyCommander
        use Drab.Commander
        public [:handler1, :handler2]

        def handler1(socket, sender) do
          ...
        end
      end

  Without marking as `public`, function may only be called from the page rendered with the corresponding controller.
  When whitelisted, functions may be called from any page using the dot syntax:

      <button drab-click="MyApp.MyCommander.handler1">handler 1</button>

  or from JS:

      Drab.exec_elixir("MyApp.MyCommander.handler1", {click: "clickety-click"});

  Running non-public functions with dot syntax raises the exception on Phoenix side.
  """
  defmacro public(handler) when is_atom(handler) do
    quote do
      public([unquote(handler)])
    end
  end

  defmacro public(handlers) when is_list(handlers) do
    quote do
      @options Map.put(@options, :public_handlers, Map.get(@options, :public_handlers) ++ unquote(handlers))
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
        Map.get(@options, m) && raise CompileError, description: "Only one `#{inspect m}` definition is allowed"
        @options Map.put(@options, m, unquote(event_handler))
      end
    end

    defmacro unquote(macro_name)(unknown_argument) do
      raise CompileError, description: """
        Only atom is allowed in `#{unquote(macro_name)}`. Given: #{inspect unknown_argument}
        """
    end
  end)

  @doc """
  Drab may allow an access to specified Plug Session values. For this, you must whitelist the keys of the
  session map. Only this keys will be available to `Drab.Core.get_session/2`

      defmodule MyApp.MyCommander do
        user Drab.Commander

        access_session [:user_id, :counter]
      end

  Keys are whitelisted due to security reasons. Session token is stored on the client-side and it is signed, but
  not encrypted.
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
    raise CompileError, description: """
      Only atom or list are allowed in `access_session`. Given: #{inspect unknown_argument}
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
        @options Map.put(@options, m, handlers ++ [{unquote(event_handler), unquote(filter)}] )
      end
    end

    defmacro unquote(macro_name)(unknown_argument, _filter) do
      raise CompileError, description: """
        only atom is allowed in `#{unquote(macro_name)}`, given: #{inspect unknown_argument}
        """
    end
  end)

  @broadcasts ~w(same_path same_controller)a
  @doc """
  Set up broadcasting listen subject for the current commander.

  It is used by broadcasting functions, like `Drab.Element.broadcast_prop/3` or `Drab.Query.insert!/2`.
  When the browser connects to Drab page, it gets the broadcasting subject from the commander. Then,
  it will receive all the broadcasts coming to this subject.

  Default is `:same_path`

  Options:

  * `:same_path` (default) - broadcasts will go to the browsers rendering the same url
  * `:same_controller` - broadcasted message will be received by all browsers, which renders the page generated
    by the same controller
  * `"topic"` - any topic you want to set, messages will go to the clients sharing this topic

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
    raise CompileError, description: """
      invalid `broadcasting` option: #{inspect unknown_argument}.

      Available: :same_path, :same_controller, "topic"
      """
  end

  @doc """
  Retrieves controller module, which generated the page the handler function is calling from, from the socket.
  """
  def controller(socket) do
    socket.assigns.__controller
  end

  @doc """
  Retrieves action name in the controller, which rendered the page where handler is called from.
  """
  def action(socket) do
    socket.assigns.__action
  end
end
