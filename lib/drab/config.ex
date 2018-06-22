defmodule Drab.Config do
  @moduledoc """
  Drab configuration related functions.

  ## Configuration options:

  ### Mandatory

  #### :main_phoenix_app
    A name of your Phoenix application (atom). If it is not set, Drab tries to guess it from
    `mix.exs`.
    Must be set when not using `Mix`.

  ### Optional

  #### :access_session *(default: [])*
    Keys of the session map, which will be included to the Drab Session globally, usually
    `:user_id`, etc. See `Drab.Commander.access_session/1` for more.

  #### :browser_response_timeout *(default: 5000)*
    Timeout, after which all functions querying/updating browser UI will give up; integer in
    milliseconds, or `:infinity`.

  #### :disable_controls_while_processing *(default: `true`)*
    After sending request to the server, sender object will be disabled until it gets the answer.
    Warning: this behaviour is not broadcasted, so only the control in the current browser is going
    to be disabled.

  #### :disable_controls_when_disconnected *(default: `true`)*
    Shall controls be disabled when there is no connectivity between the browser and the server?

  #### :default_encoder *(default: Drab.Coder.Cipher)*
    Sets the default encoder/decoder for the various functions, like `Drab.Browser.set_cookie/3`

  #### :drab_store_storage *(default: :session_storage)*
    Where to keep the Drab Store - `:memory`, `:local_storage` or `:session_storage`. Data in
    the memory is kept to the next page load, session storage persist until browser (or a tab)
    is closed, local storage is kept forever.

  #### :enable_live_scripts *(default: `false`)*
    Re-evaluation of JavaScripts containing living assigns is disabled by default.

  #### :endpoint
    Endpoint module name of your Web Application.

  #### :events_to_disable_while_processing *(default: `["click"]`)*
    Controls with those Drab events will be disabled when waiting for server response.

  #### :events_shorthands *(default: `["click", "change", "keyup", "keydown"]`)*
    The list of the shorthand attributes to be used in drab-controlled DOM object, ie:
    `<drab-click="handler">`. Please keep the list small, as it affects the client JS performance.

  #### :js_socket_constructor, *(default: "require(\"phoenix\").Socket")*
    Javascript constructor for the Socket; more info in Drab.Client.

  #### :live_conn_pass_through, *(default: `%{private: %{phoenix_endpoint: true}}`)*
    A deep map marking fields which should be preserved in the fake `@conn` assign. See `Drab.Live`
    for more detailed explanation on conn case.

  #### :phoenix_channel_options *(default: [])*
    An options passed to `use Phoenix.Channel`, for example: `[log_handle_in: false]`.

  #### :presence *(default: false)*
    Runs the `Drab.Presence` server. Defaults to false to avoid unnecessary load. See
    `Drab.Presence` for more information.

  #### :pubsub
    PubSub module name.

  #### :socket *(default: `"/socket"`)*
    Path to the socket on which Drab operates.

  #### :templates_path *(default: "priv/templates/drab")*
    Path to the user-defined Drab templates (not to be confused with Phoenix application templates,
    these are to be used internally, see `Drab.Modal` for the example usage). Must start with
    "priv/".
  """

  @doc """
  Returns the name of the client Phoenix Application

      iex> Drab.Config.app_name()
      :drab
  """
  @spec app_name :: atom | no_return
  def app_name() do
    get(:main_phoenix_app) || find_app_in_mix_exs()
  end

  @spec find_app_in_mix_exs :: atom | no_return
  defp find_app_in_mix_exs() do
    # try to find out the app name in config.exs, in compile time only
    with {:ok, pwd} <- Map.fetch(System.get_env(), "PWD"),
         {:ok, mix} <- File.read(Path.expand("mix.exs", pwd)),
         [_, app_name] <- Regex.run(~r/project\s*do.*app:\s*:(\S+),/s, mix) do
      String.to_atom(app_name)
    else
      _ -> raise_app_not_found()
    end
  end

  @doc false
  @spec ebin_dir :: String.t()
  def ebin_dir() do
    app_name() |> Application.app_dir() |> Path.join("ebin")
  end

  @spec raise_app_not_found :: no_return
  defp raise_app_not_found() do
    raise """
        Drab can't find the web application or endpoint name.

        Please add your app name and the endpoint to the config.exs:

            config :drab, main_phoenix_app: :my_app_web, endpoint: MyAppWeb.Endpoint
    """
  end

  @doc """
  Returns the Endpoint of the client Phoenix Application

      iex> Drab.Config.endpoint()
      DrabTestApp.Endpoint
  """
  @spec endpoint :: atom | no_return
  def endpoint() do
    get(:endpoint) || find_endpoint_in_app_env() || find_endpoint_in_config_exs()
  end

  @spec find_endpoint_in_app_env :: atom
  defp find_endpoint_in_app_env() do
    case app_env() do
      [{ep, _}] -> ep
      _ -> false
    end
  end

  @spec find_endpoint_in_config_exs :: atom | no_return
  defp find_endpoint_in_config_exs() do
    with {:ok, pwd} <- Map.fetch(System.get_env(), "PWD"),
         {:ok, con_exs} <- File.read(Path.expand("config/config.exs", pwd)),
         a <- inspect(app_name()),
         [_, endpoint] <- Regex.run(~r/config\s+#{a}\s*,\s*(\S+),/s, con_exs) do
      Module.concat([endpoint])
    else
      _ ->
        raise CompileError,
          description: """
          Drab is unable to find the application's endpoint.
          Please add to config:

              config :drab, endpoint: MyAppWeb.Endpoint
          """
    end
  end

  @doc """
  Returns the PubSub module of the client Phoenix Application

      iex> Drab.Config.pubsub()
      DrabTestApp.PubSub
  """
  @spec pubsub :: atom | no_return
  def pubsub() do
    get(:pubsub) || with config <- Drab.Config.app_config(),
         {:ok, pubsub_conf} <- Keyword.fetch(config, :pubsub),
         {:ok, name} <- Keyword.fetch(pubsub_conf, :name) do
      name
    else
      _ ->
        raise """
        Can't find the PubSub module.
        Please add to config.exs:

            config :drab, pubsub: MyApp.PubSub
        """
    end
  end

  @doc """
  Returns the Phoenix Application module atom

      iex> Drab.Config.app_module()
      DrabTestApp
  """
  @spec app_module :: atom
  def app_module() do
    # in 1.3 app module is not under the endpoint
    endpoint()
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end

  @doc """
  Returns all environment for the default main Application

      iex> is_list(Drab.Config.app_config())
      true
  """
  @spec app_env :: Keyword.t()
  def app_env() do
    Application.get_all_env(app_name())
  end

  @doc """
  Returns any config key for current main Application

      iex> Drab.Config.app_config(:secret_key_base) |> String.length()
      64
  """
  @spec app_config(atom) :: term
  def app_config(config_key) do
    app_config() |> Keyword.fetch!(config_key)
    # app_env() |> Keyword.fetch!(endpoint()) |> Keyword.fetch!(config_key)
  end

  @doc """
  Returns the config for current main Application

      iex> is_list(Drab.Config.app_config())
      true
  """
  @spec app_config :: Keyword.t()
  def app_config() do
    with {:ok, app_config} <- Keyword.fetch(app_env(), endpoint()) do
      app_config
    else
      _ -> raise_app_not_found()
    end
  end

  @doc """
  Returns configured Drab.Live.Engine Extension. String with dot at the begin.

  Example, for config:

      config :phoenix, :template_engines,
        drab: Drab.Live.Engine

  it will return ".drab"

      iex> Drab.Config.drab_extension()
      ".drab"
  """
  @spec drab_extension :: String.t()
  def drab_extension() do
    {drab_ext, Drab.Live.Engine} =
      :phoenix
      |> Application.get_env(:compiled_template_engines)
      |> Enum.find(fn {_, v} -> v == Drab.Live.Engine end)

    "." <> to_string(drab_ext)
  end

  @doc false
  @spec default_controller_for(atom | nil) :: atom | nil
  def default_controller_for(commander) do
    replace_last(commander, "Commander", "Controller")
  end

  @doc false
  @spec default_view_for(atom | nil) :: atom | nil
  def default_view_for(commander) do
    replace_last(default_controller_for(commander), "Controller", "View")
  end

  @doc false
  @spec default_commander_for(atom | nil) :: atom | nil
  def default_commander_for(controller) do
    replace_last(controller, "Controller", "Commander")
  end

  @spec replace_last(atom, String.t(), String.t()) :: atom
  defp replace_last(atom, from, to) do
    path = Module.split(atom)
    new_last = path |> List.last() |> String.replace(from, to)
    new_path = List.replace_at(path, -1, new_last)
    Module.concat(new_path)
  end

  @doc false
  @spec drab_internal_commanders() :: list
  def drab_internal_commanders() do
    [Drab.Logger]
  end

  @doc """
  Returns Drab configuration for the given atom.

      iex> Drab.Config.get(:templates_path)
      "priv/custom_templates"

  All the config values may be override in `config.exs`, for example:

      config :drab, disable_controls_while_processing: false
  """
  @spec get(atom) :: term
  def get(:disable_controls_while_processing),
    do: Application.get_env(:drab, :disable_controls_while_processing, true)

  def get(:events_to_disable_while_processing),
    do: Application.get_env(:drab, :events_to_disable_while_processing, ["click"])

  def get(:events_shorthands),
    do: Application.get_env(:drab, :events_shorthands, ["click", "change", "keyup", "keydown"])

  def get(:disable_controls_when_disconnected),
    do: Application.get_env(:drab, :disable_controls_when_disconnected, true)

  def get(:socket), do: Application.get_env(:drab, :socket, "/socket")

  def get(:drab_store_storage),
    do: Application.get_env(:drab, :drab_store_storage, :session_storage)

  def get(:browser_response_timeout),
    do: Application.get_env(:drab, :browser_response_timeout, 5000)

  def get(:main_phoenix_app), do: Application.get_env(:drab, :main_phoenix_app, nil)

  def get(:enable_live_scripts), do: Application.get_env(:drab, :enable_live_scripts, false)

  def get(:phoenix_channel_options), do: Application.get_env(:drab, :phoenix_channel_options, [])

  def get(:templates_path), do: Application.get_env(:drab, :templates_path, "priv/templates/drab")

  def get(:default_encoder), do: Application.get_env(:drab, :default_encoder, Drab.Coder.Cipher)

  def get(:js_socket_constructor),
    do: Application.get_env(:drab, :js_socket_constructor, "require(\"phoenix\").Socket")

  def get(:presence), do: Application.get_env(:drab, :presence, false)

  def get(:endpoint), do: Application.get_env(:drab, :endpoint, nil)

  def get(:pubsub), do: Application.get_env(:drab, :pubsub, nil)

  def get(:access_session) do
    if get(:presence) do
      [get(:presence, :id) | Application.get_env(:drab, :access_session, [])]
    else
      Application.get_env(:drab, :access_session, [])
    end
  end

  def get(:live_conn_pass_through) do
    Application.get_env(:drab, :live_conn_pass_through, %{
      private: %{
        phoenix_endpoint: true
      }
    })
  end

  def get(_), do: nil

  def get(:presence, :id) do
    case get(:presence) do
      options when is_list(options) -> Keyword.get(options, :id, :user_id)
      _ -> nil
    end
  end

  def get(:presence, :module) do
    case get(:presence) do
      options when is_list(options) -> Keyword.get(options, :module, Drab.Presence)
      _ -> Drab.Presence
    end
  end
end
