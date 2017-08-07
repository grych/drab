defmodule Drab.Supervisor do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    # children = [
    #   # Start the endpoint when the application starts
    #   # supervisor(DrabTestApp.Endpoint, []),
    #   # Start your own worker by calling: DrabTestApp.Worker.start_link(arg1, arg2, arg3)
    #   # worker(DrabTestApp.Worker, [arg1, arg2, arg3]),
    # ]

    # Logger.info "Starting Drab"

    # Run Drab Test App endpoint, when running tests or development
    children = case Code.ensure_compiled(DrabTestApp) do
      {:error, _} -> []
      {:module, DrabTestApp} -> [supervisor(DrabTestApp.Endpoint, [])]
    end 

    # Start ETS cache
    Drab.Live.Cache.start()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Drab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # def config_change(changed, _new, removed) do
  #   DrabTestApp.Endpoint.config_change(changed, removed)
  #   :ok
  # end
end
