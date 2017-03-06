## 0.3.0
Changes:
* display information when handler die (like error 500 page), different for prod and dev (Drab.Core)
* select(:val) returns first value instead of the list
* Drab.Query.select(:vals) returns a map of of %{name|id|undefined_XX: value} instead of [value] 

## 0.4.0
Changes:

## Future
Changes:
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
* compress Drab templates

## Bugs or features?
* Drab.Socket steels all `connect` callbacks. Bad Drab
