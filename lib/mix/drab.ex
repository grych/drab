defmodule Mix.Drab do
  @moduledoc false

  def app_name() do
    app = Mix.Project.config()[:app]

    unless app do
      Mix.shell().error("Can't find the application name.")

      Mix.shell().info("""
      If your web application is under an umbrella, please change directory there and try again.
      """)

      Mix.raise("Giving up.")
    end

    app
  end

  @doc false
  @spec find_endpoint_in_config_exs(atom) :: atom | no_return
  def find_endpoint_in_config_exs(app_name) do
    with {:ok, pwd} <- Map.fetch(System.get_env(), "PWD"),
         {:ok, con_exs} <- File.read(Path.expand("config/config.exs", pwd)),
         a <- inspect(app_name),
         [_, endpoint] <- Regex.run(~r/config\s+#{a}\s*,\s*(\S+),/s, con_exs) do
      Module.concat([endpoint])
    else
      _ ->
        Mix.shell().error("Drab is unable to find the endpoint of `#{inspect(app_name)}`.")
        Mix.raise("Giving up.")
    end
  end

  @doc false
  @spec find_app_in_mix_exs :: atom | no_return
  def find_app_in_mix_exs() do
    # try to find out the app name in config.exs, in compile time only
    with {:ok, pwd} <- Map.fetch(System.get_env(), "PWD"),
         {:ok, mix} <- File.read(Path.expand("mix.exs", pwd)),
         [_, app_name] <- Regex.run(~r/project\s*do.*app:\s*:(\S+),/s, mix) do
      String.to_atom(app_name)
    else
      _ ->
        Mix.shell().error("Drab is unable to find the application name.")
        Mix.raise("Giving up.")
    end
  end
end
