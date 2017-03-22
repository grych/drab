## 0.4.0
Changes:

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* rewrite Drab.Query - use meta, Luke!
* broadcast to all except you
* tests, tests, tests
* benchmarks
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
