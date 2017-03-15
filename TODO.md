## 0.3.1
Changes:
* display information when handler die (like error 500 page), different for prod and dev (Drab.Core)
* Drab.socket() returns current socket, so you can test Drab from iex console

## 0.4.0
Changes:

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* *** use GenServer, Luke!
* rewrite Drab.Query - use meta, Luke!
* tests, tests, tests
* benchmarks
* debuggin console
* timeout for event handlers
* timeout for Drab.Query and Drab.Modal functions
* specify on which pages drab broadcasts, with wildcard
* dependencies for modules (for ex. Modal depends on Query)
* extract Drab Store and Session to standalone module (loaded by default)
* group JS commands to be launched in one step
* render templates, views in commanders (accutally it can already be done, must thing about some helpers)
* render Drab templates in a compile-time
* compress Drab templates (js)

## Bugs or features?
* Drab.Socket steals all `connect` callbacks. Bad Drab
