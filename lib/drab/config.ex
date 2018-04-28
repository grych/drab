defmodule Drab.Config do
  @moduledoc """
  Drab configuration related functions.

  ## Configuration options:

  #### :disable_controls_while_processing *(default: `true`)*
    After sending request to the server, sender object will be disabled until it gets the answer.
    Warning: this behaviour is not broadcasted, so only the control in the current browser is going
    to be disabled.

  #### :disable_controls_when_disconnected *(default: `true`)*
    Shall controls be disabled when there is no connectivity between the browser and the server?

  #### :events_to_disable_while_processing *(default: `["click"]`)*
    The list of events which will be disabled when waiting for server response.

  #### :events_shorthands *(default: `["click", "change", "keyup", "keydown"]`)*
    The list of the shorthand attributes to be used in drab-controlled DOM object, ie:
    `<drab-click="handler">`. Please keep the list small, as it affects the client JS performance.

  #### :socket *(default: `"/socket"`)*
    Path to the socket on which Drab operates.

  #### :drab_store_storage *(default: :session_storage)*
    Where to keep the Drab Store - `:memory`, `:local_storage` or `:session_storage`. Data in
    the memory is kept to the next page load, session storage persist until browser (or a tab)
    is closed, local storage is kept forever.

  #### :browser_response_timeout *(default: 5000)*
    Timeout, after which all functions querying/updating browser UI will give up; integer in
    milliseconds, or `:infinity`.

  #### :main_phoenix_app
    A name of your Phoenix application (atom). If it is not set, Drab tries to guess it from from
    the `mix.exs`.
    Must be set when not using `Mix`.

  #### :enable_live_scripts *(default: `false`)*
    Re-evaluation of JavaScripts containing living assigns is disabled by default.

  #### :live_helper_modules *(default: `[Router.Helpers, ErrorHelpers, Gettext]`)*
    A list of modules to be imported when Drab.Live evaluates expression with living assigns.

  #### :live_conn_pass_through, *(default: `%{private: %{phoenix_endpoint: true}}`)*
    A deep map marking fields which should be preserved in the fake `@conn` assign. See `Drab.Live`
    for more detailed explanation on conn case.

  #### :templates_path *(default: "priv/templates/drab")*
    Path to the user-defined Drab templates (not to be confused with Phoenix application templates,
    these are to be used internally, see `Drab.Modal` for the example usage). Must start with
    "priv/".

  #### :phoenix_channel_options *(default: [])*
    An options passed to `use Phoenix.Channel`, for example: `[log_handle_in: false]`.
  """

  @doc """
  Returns the name of the client Phoenix Application

      iex> Drab.Config.app_name()
      :drab
  """
  @spec app_name :: atom
  def app_name() do
    get(:main_phoenix_app) ||
      case Code.ensure_loaded(Mix.Project) do
        {:module, Mix.Project} -> Mix.Project.config()[:app] || raise_app_not_found()
        {:error, _} -> raise_app_not_found()
      end
  end

  @spec raise_app_not_found :: no_return
  defp raise_app_not_found() do
    raise """
    drab can't find the main Phoenix application name.

    Please check your mix.exs or set the name in confix.exs:

        config :drab, main_phoenix_app: :my_app
    """
  end

  @doc """
  Returns the Endpoint of the client Phoenix Application

      iex> Drab.Config.endpoint()
      DrabTestApp.Endpoint
  """
  @spec endpoint :: atom
  def endpoint() do
    {endpoint, _} =
      app_env()
      |> Enum.filter(fn {x, _} -> first_uppercase?(x) end)
      |> Enum.find(fn {base, _} ->
        is_endpoint?(base)
      end)

    endpoint
  end

  @doc """
  Returns the PubSub module of the client Phoenix Application

      iex> Drab.Config.pubsub()
      DrabTestApp.PubSub
  """
  @spec pubsub :: atom | no_return
  def pubsub() do
    with {:ok, pubsub_conf} <- Keyword.fetch(Drab.Config.app_config(), :pubsub),
         {:ok, name} <- Keyword.fetch(pubsub_conf, :name) do
      name
    else
      _ ->
        raise """
        Can't find the PubSub module. Please ensure that it exists in config.exs.
        """
    end
  end

  @spec first_uppercase?(atom) :: boolean
  defp first_uppercase?(atom) do
    x = atom |> Atom.to_string() |> String.first()
    x == String.upcase(x)
  end

  # TODO: find a better way to check if the module is an Endpoint
  @spec is_endpoint?(atom) :: boolean
  defp is_endpoint?(module) when is_atom(module) do
    {loaded, _} = Code.ensure_loaded(module)

    loaded == :module && function_exported?(module, :struct_url, 0) &&
      function_exported?(module, :url, 0)
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
    app_env() |> Keyword.fetch!(endpoint()) |> Keyword.fetch!(config_key)
  end

  @doc """
  Returns the config for current main Application

      iex> is_list(Drab.Config.app_config())
      true
  """
  @spec app_config :: Keyword.t()
  def app_config() do
    Keyword.fetch!(app_env(), endpoint())
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

  def get(:live_helper_modules) do
    case Application.get_env(:drab, :live_helper_modules, [Router.Helpers, ErrorHelpers, Gettext]) do
      list when is_list(list) ->
        with_app_module(list)

      # for backwards compatibility
      tuple when is_tuple(tuple) ->
        with_app_module(Tuple.to_list(tuple))
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

  @spec with_app_module(list) :: list
  defp with_app_module(list), do: Enum.map(list, fn x -> Module.concat(app_module(), x) end)
end
