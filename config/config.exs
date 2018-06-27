# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :drab, DrabTestApp.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bP1ZF+DDZiAVGuIigj3UuAzBhDmxHSboH9EEH575muSET1g18BPO4HeZnggJA/7q",
  render_errors: [view: DrabTestApp.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DrabTestApp.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :phoenix, :template_engines, drab: Drab.Live.Engine

# config :floki, :encode_raw_html, false



config :drab, DrabTestApp.Endpoint,
  otp_app: :drab,
  templates_path: "priv/custom_templates"



# config :drab, templates_path: "priv/custom_templates"

config :drab, enable_live_scripts: true

config :drab, :events_shorthands, ["click", "keyup", "keydown", "change", "mousedown"]

config :drab, :phoenix_channel_options, log_handle_in: false

config :drab, :live_conn_pass_through, %{
  assigns: %{
    current_user: true
  },
  private: %{
    phoenix_endpoint: true
  }
}

config :drab, :presence, true
