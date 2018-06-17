defmodule Drab.Supervisor do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    # Run Drab Test App endpoint, when running tests or development
    children =
      case Code.ensure_compiled(DrabTestApp) do
        {:error, _} -> []
        {:module, DrabTestApp} -> [supervisor(DrabTestApp.Endpoint, []), Drab.Presence]
      end

    # children = if Drab.Config.get(:presence) do
    #   children ++ [Drab.Presence]
    # else
    #   children
    # end

    opts = [strategy: :one_for_one, name: Drab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # def config_change(changed, _new, removed) do
  #   DrabTestApp.Endpoint.config_change(changed, removed)
  #   :ok
  # end
end
