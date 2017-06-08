defmodule Drab.Config do
  @moduledoc """
  Drab configuration related functions.
  """
  
  @doc """
  Returns the name of the client Phoenix Application
  """
  def app_name() do
    Mix.Project.config()[:app] || raise """
      Can't find the main application name. Please check your mix.exs
      """
  end

  @doc """
  Returns the Endpoint of the client Phoenix Application
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

  defp first_uppercase?(atom) do
    x = atom |> Atom.to_string() |> String.first()
    x == String.upcase(x)
  end

  # TODO: find a better way to check if the module is an Endpoint
  defp is_endpoint?(module) when is_atom(module) do
    {loaded, _} = Code.ensure_loaded(module)
    loaded == :module 
      && Drab.function_exists?(module, "struct_url") 
      && Drab.function_exists?(module, "url")
  end

  @doc """
  Returns the Phoenix Application module atom
  """
  def app_module() do
    Module.split(endpoint()) 
    |> Enum.drop(-1)
    |> Module.concat()
  end

  @doc """
  Returns all environment for the default main Application
  """
  def app_env() do
    Application.get_all_env(app_name()) 
  end

  @doc """
  Returns any config key for current main Application

      iex> Drab.app_config(:secret_key_base)
      "bP1ZF+DDZiAVGuIigj3UuAzBhDmxHSboH9EEH575muSET1g18BPO4HeZnggJA/7q"
  """
  def app_config(config_key) do
    Keyword.fetch!(app_env(), endpoint()) |> Keyword.fetch!(config_key)
  end

  @doc """
  Returns the config for current main Application
  """
  def app_config() do
    Keyword.fetch!(app_env(), endpoint())
  end


  @doc """
  Returns Drab configuration for the given atom.

      iex> Drab.Config.get(:templates_path)
      "priv/templates/drab"
  
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
  """
  def get(:templates_path), do: 
    Application.get_env(:drab, :templates_path, "priv/templates/drab")
  def get(:disable_controls_while_processing),  do: Application.get_env(:drab, :disable_controls_while_processing, true)
  def get(:events_to_disable_while_processing), do: Application.get_env(:drab, :events_to_disable_while_processing, ["click"])
  def get(:disable_controls_when_disconnected), do: Application.get_env(:drab, :disable_controls_when_disconnected, true)
  def get(:socket), do:                             Application.get_env(:drab, :socket, "/socket")
  def get(:drab_store_storage), do:                 Application.get_env(:drab, :drab_store_storage, :session_storage)
  def get(:browser_response_timeout), do:           Application.get_env(:drab, :browser_response_timeout, 5000)
  def get(_), do: nil

  @doc """
  Depreciated. Use `get/1` instead.
  """
  def config() do
    IO.warn """
    `Drab.config` has been depreciated. Please use `Drab.Config.get/1` instead
     """
    %{
      templates_path: Application.get_env(:drab, :templates_path, "priv/templates/drab"),
      disable_controls_while_processing: Application.get_env(:drab, :disable_controls_while_processing, true),
      events_to_disable_while_processing: Application.get_env(:drab, :events_to_disable_while_processing, ["click"]),
      disable_controls_when_disconnected: Application.get_env(:drab, :disable_controls_when_disconnected, true),
      socket: Application.get_env(:drab, :socket, "/socket"),
      drab_store_storage: Application.get_env(:drab, :drab_store_storage, :session_storage)
    }
  end

end
