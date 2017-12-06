defmodule Drab.Config do
  @moduledoc """
  Drab configuration related functions.
  """

  @doc """
  Returns the name of the client Phoenix Application

      iex> Drab.Config.app_name()
      :drab
  """
  def app_name() do
    get(:main_phoenix_app) || case Code.ensure_loaded(Mix.Project) do
      {:module, Mix.Project} -> Mix.Project.config()[:app] || raise_app_not_found()
      {:error, _} -> raise_app_not_found()
    end
  end

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
  def endpoint() do
    # IO.inspect app_env()
    # TODO: bad performance
    {endpoint, _} = app_env()
    |> Enum.filter(fn {x, _} -> first_uppercase?(x) end)
    |> Enum.find(fn {base, _} ->
      # Code.ensure_compiled(base) # needs to be compiled before View
      is_endpoint?(base)
    end)
    endpoint
  end

  @doc """
  Returns the PubSub module of the client Phoenix Application

      iex> Drab.Config.pubsub()
      DrabTestApp.PubSub
  """
  def pubsub() do
    with {:ok, pubsub_conf} <- Keyword.fetch(Drab.Config.app_config(), :pubsub),
         {:ok, name} <- Keyword.fetch(pubsub_conf, :name)
    do
      name
    else
      _ -> raise """
      Can't find the PubSub module. Please ensure that it exists in config.exs.
      """
    end
  end

  defp first_uppercase?(atom) do
    x = atom |> Atom.to_string() |> String.first()
    x == String.upcase(x)
  end

  # TODO: find a better way to check if the module is an Endpoint
  defp is_endpoint?(module) when is_atom(module) do
    {loaded, _} = Code.ensure_loaded(module)
    loaded == :module
      && function_exported?(module, :struct_url, 0)
      && function_exported?(module, :url, 0)
  end

  @doc """
  Returns the Phoenix Application module atom

      iex> Drab.Config.app_module()
      DrabTestApp
  """
  def app_module() do
    # in 1.3 app module is not under the endpoint
    Module.split(endpoint())
    |> Enum.drop(-1)
    |> Module.concat()
  end

  @doc """
  Returns all environment for the default main Application

      iex> is_list(Drab.Config.app_config())
      true
  """
  def app_env() do
    Application.get_all_env(app_name())
  end

  @doc """
  Returns any config key for current main Application

      iex> Drab.app_config(:secret_key_base)
      "bP1ZF+DDZiAVGuIixHSboET1g18BPO4HeZnggJA/7q"
  """
  def app_config(config_key) do
    Keyword.fetch!(app_env(), endpoint()) |> Keyword.fetch!(config_key)
  end

  @doc """
  Returns the config for current main Application

      iex> is_list(Drab.Config.app_config())
      true
  """
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
  def drab_extension() do
    {drab_ext, Drab.Live.Engine} = Application.get_env(:phoenix, :compiled_template_engines)
      |> Enum.find(fn {_, v} -> v == Drab.Live.Engine end)
    "." <> to_string(drab_ext)
  end

  @doc """
  Returns Drab configuration for the given atom.

      iex> Drab.Config.get(:templates_path)
      "test/support/priv/templates/drab"

  All the config values may be override in `config.exs`, for example:

      config :drab, disable_controls_while_processing: false

  Configuration options:
  * `templates_path` (default: "priv/templates/drab") - path to the user templates (may be new or override default
    templates)
  * `disable_controls_while_processing` (default: `true`) - after sending request to the server, sender will be
    disabled until get the answer; warning: this behaviour is not broadcasted, so only the control in the current
    browers will be disabled
  * `events_to_disable_while_processing` (default: `["click"]`) - list of events which will be disabled when
    waiting for server response
  * `disable_controls_when_disconnected` (default: `true`) - disables control when there is no connectivity
    between the browser and the server
  * `socket` (default: `"/socket"`) - path to the socket where Drab operates
  * `drab_store_storage` (default: :session_storage) - where to keep the Drab Store - :memory, :local_storage or
    :session_storage; data in memory is kept to the next page load, session storage persist until browser (or a tab) is
    closed, and local storage is kept forever
  * `browser_response_timeout` - timeout, after which all functions querying/updating browser UI will give up; integer
    in milliseconds or `:infinity`
  * `main_phoenix_app` - a name of your Phoenix application (atom); if not set it gets it from the `mix.exs`
  * `enable_live_scripts` - true for re-evaluate javascripts contain living assigns
  * `live_helper_modules` - a list of modules to be imported when Drab.Live evaluates expression with living assign;
    default is `[Router.Helpers, ErrorHelpers, Gettext]`
  """
  def get(:templates_path), do:
    Application.get_env(:drab, :templates_path, "priv/templates/drab")
  def get(:disable_controls_while_processing), do:
    Application.get_env(:drab, :disable_controls_while_processing, true)
  def get(:events_to_disable_while_processing), do:
    Application.get_env(:drab, :events_to_disable_while_processing, ["click"])
  def get(:disable_controls_when_disconnected), do:
    Application.get_env(:drab, :disable_controls_when_disconnected, true)
  def get(:socket), do:
    Application.get_env(:drab, :socket, "/socket")
  def get(:drab_store_storage), do:
    Application.get_env(:drab, :drab_store_storage, :session_storage)
  def get(:browser_response_timeout), do:
    Application.get_env(:drab, :browser_response_timeout, 5000)
  def get(:main_phoenix_app), do:
    Application.get_env(:drab, :main_phoenix_app, nil)
  def get(:enable_live_scripts), do:
    Application.get_env(:drab, :enable_live_scripts, false)
  def get(:live_helper_modules) do
    case Application.get_env(:drab, :live_helper_modules, [Router.Helpers, ErrorHelpers, Gettext]) do
      list when is_list(list) -> with_app_module(list)
      tuple when is_tuple(tuple) -> with_app_module(Tuple.to_list(tuple)) # for backwards compatibility
    end
  end
  def get(_), do:
    nil

  defp with_app_module(list), do:
    Enum.map list, fn x -> Module.concat(app_module(), x) end

end
