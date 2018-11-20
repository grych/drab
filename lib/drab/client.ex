defmodule Drab.Client do
  @moduledoc """
  Enable Drab on the browser side. Must be included in HTML template, for example
  in `web/templates/layout/app.html.eex`:

      <%= Drab.Client.run(@conn) %>

  after the line which loads app.js:

      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>

  at the very end of the layout (after template rendering functions).

  ## Own channels inside the Drab's socket
  On the browser side, there is a global object `Drab`, which you may use to create your own
  channels inside Drab Socket:

      ch = Drab.socket.channel("mychannel:whatever")
      ch.join()

  ## Custom socket constructor (Webpack "require is not defined" fix)
  If you are using JS bundler other than default brunch, the `require` method may not be availabe
  as global. In this case, you might see the error:

      require is not defined

  in the Drab's javascript, in line:

      this.Socket = require("phoenix").Socket;

  In this case, you must provide it. In the `app.js` add a global variable, which will be passed
  to Drab later:

      window.__socket = require("phoenix").Socket;

  Then, tell Drab to use this instead of default `require("phoenix").Socket`. Add to `config.exs`:

      config :drab, MyAppWeb.Endpoint,
        js_socket_constructor: "window.__socket"

  This will change the problematic line in Drab's javascript to:

      this.Socket = window.__socket;

  ## Drab JS client API
  ### Drab.connect(token_object)
  Connects to the Drab's websocket. Must be called after injecting JS code with
  `Drab.Client.generate/2`:

      <%= Drab.Client.generate(@conn) %>
      <script>
        if (window.Drab) Drab.connect({auth_token: window.my_token});
      </script>


  ### Drab.exec_elixir(elixir_function_name, argument, callback)
  Run elixir function (which must be a handler in the commander) from the browser side.

  Arguments:
  * elixir_function_name(string) - function name
  * argument(object) - the object will be passed to the handler function; if it is not an object,
    it is converted to `{payload: argumen}`
  * callback - callback function runs after event handler finish

  Function name may be given with the commander name, like "MyApp.MyCommander.handler_function",
  or the function name only: "handler_function". In this case the corresponding commander module
  will be used. This function must be marked as public with `Drab.Commander.public/1` or `defhandler` macro.

  Returns:
  * no return

  Example:

      <button onclick="Drab.exec_elixir('clicked', {click: 'clickety-click'});">
        Clickme
      </button>

  The code above runs function named `clicked` in the corresponding Commander, with
  the argument `%{"click" => "clickety-click}"`

  ### Drab.enable_drab_on(selector_or_node)
  Evaluates DOM to set up Drab events.

  Called automatically on page load for the whole document. You need to call it after
  adding/changing html fragments from the client side. No need to call it when updating html
  with Drab commands (`poke`, `insert_html`, etc).

  Arguments:
  * selector_or_node - DOM object or its selector under which Drab re-evaluate the html; uses
  `document` if not given

  Return:
  * no return
  """

  import Drab.Template
  require Logger

  # changing the client API version will cause reload browsers with the different version
  # must be a string
  @client_lib_version "15"

  @doc """
  Generates JS code and runs Drab.

  Passes controller and action name, tokenized for safety. Works only when the controller, which
  renders the current action, has a corresponding commander, or has been compiled with
  `use Drab.Controller`.

  Optional argument may be a list of parameters which will be added to assigns to the socket.
  Example of `layout/app.html.eex`:

      <%= Drab.Client.run(@conn) %>
      <%= Drab.Client.run(@conn, user_id: 4, any_other: "test") %>

  Please remember that your parameters are passed to the browser as Phoenix Token. Token is signed,
  but not ciphered. Do not put any secret data in it.
  """
  @spec run(Plug.Conn.t(), Keyword.t()) :: String.t()
  def run(conn, assigns \\ []) do
    generate_drab_js(conn, true, assigns)
  end

  @doc """
  Like `run/2`, but does not connect to the Drab socket.

  It is intended to use when you need to pass the additional tokens, eg. for authorization.
  To connect, use `Drab.connect(object)` JS function.

      <script>
        window.my_token = ...
      </script>
      <%= Drab.Client.generate(@conn) %>
      <script>
        if (window.Drab) Drab.connect({auth_token: window.my_token});
      </script>

  Like in `run/2`, you may use optional arguments, which will become socket's assigns.

  Please check `Drab.Socket` for more information about how to handle the auth tokens with Drab.
  """
  @spec generate(Plug.Conn.t(), Keyword.t()) :: String.t()
  def generate(conn, assigns \\ []) do
    generate_drab_js(conn, false, assigns)
  end

  @doc false
  @spec api_version() :: String.t()
  def api_version(), do: @client_lib_version

  @spec generate_drab_js(Plug.Conn.t(), boolean, Keyword.t()) :: String.t()
  defp generate_drab_js(conn, connect?, assigns) do
    controller = Phoenix.Controller.controller_module(conn)

    if enables_drab?(controller) do
      commander = commander_for(controller)
      view = view_for(controller)
      endpoint = Phoenix.Controller.endpoint_module(conn)
      action = Phoenix.Controller.action_name(conn)

      controller_and_action =
        Phoenix.Token.sign(
          conn,
          "controller_and_action",
          controller: controller,
          commander: commander,
          view: view,
          action: action,
          assigns: assigns
        )

      broadcast_topic =
        topic(commander.__drab__().broadcasting, controller, conn.request_path, action)

      templates = DrabModule.all_templates_for(commander.__drab__().modules)

      access_session =
        Enum.uniq(
          commander.__drab__().access_session ++ Drab.Config.get(endpoint, :access_session)
        )

      session =
        access_session
        |> Enum.map(fn x -> {x, Plug.Conn.get_session(conn, x)} end)
        |> Enum.into(%{})

      session_token = Drab.Core.tokenize_store(conn, session)

      bindings = [
        controller_and_action: controller_and_action,
        endpoint: endpoint,
        commander: commander,
        templates: templates,
        drab_session_token: session_token,
        broadcast_topic: broadcast_topic,
        connect: connect?,
        client_lib_version: @client_lib_version
      ]

      js = render_template(endpoint, "drab.js", bindings)

      Phoenix.HTML.raw("""
      <script>
        #{js}
      </script>
      """)
    else
      ""
    end
  end

  defp commander_for(controller) do
    case Enum.member?(controller.module_info(:exports), {:__drab__, 0}) do
      true -> controller.__drab__()[:commander]
      _ -> Drab.Config.default_commander_for(controller)
    end
  end

  defp view_for(controller) do
    case Enum.member?(controller.module_info(:exports), {:__drab__, 0}) do
      true -> controller.__drab__()[:view]
      _ -> Drab.Config.default_view_for(controller)
    end
  end

  @spec enables_drab?(atom) :: boolean
  defp enables_drab?(controller) do
    # Enable Drab only if Controller compiles with `use Drab.Controller`
    # or default commander exists
    case Enum.member?(controller.module_info(:exports), {:__drab__, 0}) do
      true ->
        true

      _ ->
        commander = Drab.Config.default_commander_for(controller)

        Code.ensure_compiled?(commander) and
          Enum.member?(commander.module_info(:exports), {:__drab__, 0})
    end
  end

  # defp topic(:all, _, _), do: "all"
  @spec topic(atom | String.t(), atom | String.t(), atom | String.t(), atom | String.t()) ::
          String.t()
  defp topic(:same_path, _, path, _), do: Drab.Core.same_path(path)
  defp topic(:same_controller, controller, _, _), do: Drab.Core.same_controller(controller)
  defp topic(:same_action, controller, _, action), do: Drab.Core.same_action(controller, action)
  defp topic(topic, _, _, _) when is_binary(topic), do: Drab.Core.same_topic(topic)
end
