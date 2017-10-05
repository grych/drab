use Mix.Config

config :drab, DrabTestApp.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure ExDoc to use makeup for syntax highlighting
config :ex_doc, :markdown_processor, Makedown.ExDoc
