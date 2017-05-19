defmodule Drab.Ampere.Engine do
  @moduledoc false

#   Usage

# Add {:phoenix_haml, "~> 0.2"} to your deps in mix.exs. If you generated your app from the Phoenix master branch, add phoenix_haml's master branch to your deps instead. {:phoenix_haml, github: "chrismccord/phoenix_haml"}

# Add the following to your Phoenix config/config.exs

# config :phoenix, :template_engines,
#   haml: PhoenixHaml.Engine
#  ```
# Use the .html.haml extensions for your templates.
# Optional

# Add haml extension to Phoenix live reload in config/dev.exs

#   config :hello_phoenix, HelloPhoenix.Endpoint,
#     live_reload: [
#       patterns: [
#         ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
#         ~r{web/views/.*(ex)$},
#         ~r{web/templates/.*(eex|haml)$}
#       ]
#     ]

  @behaviour Phoenix.Template.Engine

  def compile(path, _name) do
    File.read!(path) |> EEx.compile_string(engine: Drab.Ampere.EExEngine , file: path, line: 1)
  end
end
