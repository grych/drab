#TODO: remove in 1.0
if Application.get_env(:drab, :main_phoenix_app) do
  raise CompileError, description: """
    Drab configuration has changed.
    Instead of specyfing :main_phoenix_app, use config for the particular endpoints:

        config :drab, MyAppWeb.Endpoint,
          otp_app: :my_app_web,
          ... # other drab related config

    More information: https://hexdocs.pm/drab/Drab.Config.html

    """
end
