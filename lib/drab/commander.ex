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
  Event handler is the function which process on request which comes from the browser. Most basically it is
  done by running JS method `Drab.run_handler()`. See `Drab.Core` for this method description.

  The event handler function receives two parameters:
  * `socket` - the websocket used to communicate back to the page by `Drab.Query` functions
  * `argument` - an argument used in JS Drab.run_handler() method; when using Drab.Query module it is
    the `dom_sender` map (see `Drab.Query` for full description)

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

        def check_status(socket, dom_sender) do
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
  in order or appearance, then system checks if any of them returned false

  Can be filtered by `:only` or `:except` options:

      before_handler :check_status, except: [:set_status]
      before_handler :check_status, only:   [:update_db]

  #### `after_handler` 
  Runs after the event handler. Gets return value of the event handler function as a third argument.
  Can be filtered by `:only` or `:except` options, analogically to `before_handler`

  ## Modules

  Drab is modular. You my choose which modules to use in the specific Commander by using `:module` option
  in `use Drab.Commander` directive. 
  There is one required module, which is loaded always and can't be disabled: `Drab.Code`. By default, modules
  `Drab.Query` and `Drab.Modal` are loaded. The following code:

      use Drab.Commander, modules: [Drab.Query]

  will override default modules, so only `Drab.Core` and `Drab.Query` will be available.

  Every module has its corresponding JS template, which is loaded only when module is enabled.

  ## Generate the Commander

  There is a mix task (`Mix.Tasks.Drab.Gen.Commander`) to generate skeleton of commander:

      mix drab.gen.commander Name

  See also `Drab.Controller`
  """

  defmacro __using__(options) do
    quote do
      import unquote(__MODULE__)
      import Drab.Core

      o = Enum.into(unquote(options) || [], %{commander: __MODULE__})
      Enum.each([:onload, :onconnect, :ondisconnect, :access_session], fn macro_name -> 
        if o[macro_name] do
          IO.warn("""
            Defining #{macro_name} handler in the use statement has been depreciated. Please use corresponding macro instead.
            """, Macro.Env.stacktrace(__ENV__))
        end
      end)
      @options Map.merge(%Drab.Commander.Config{}, o) 

      unquote do
        opts = Map.merge(%Drab.Commander.Config{}, Enum.into(options, %{}))
        opts.modules |> Enum.map(fn module -> 
          quote do
            import unquote(module)
          end
        end)
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
        @options Map.put(@options, m, [{unquote(event_handler), unquote(filter)} | handlers])
      end
    end

    defmacro unquote(macro_name)(unknown_argument, _filter) do
      raise CompileError, description: """
        Only atom is allowed in `#{unquote(macro_name)}`. Given: #{inspect unknown_argument}
        """
    end
  end)

end
