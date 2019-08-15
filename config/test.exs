use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :drab, DrabTestApp.Endpoint,
  http: [port: 4001],
  server: true,
  live_view: [
     signing_salt: "+iGXfLGYMPyowoZribxgrSyeaPz9D/v2"
   ]

# Print only warnings and errors during test
config :logger, level: :warn

# phantomjs does not work correctly, shows some JS circular errors
# , browser: "chrome_headless"
config :hound, driver: "chrome_driver", browser: "chrome_headless"
# config :hound, driver: "selenium"
# config :hound, browser: "chrome"
# config :hound, driver: "phantomjs"

# config :drab,
#   drab_store_storage: :local_storage
