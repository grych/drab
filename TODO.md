## 0.3.0
Changes:
* waiter functionality
* display information when handler die (like error 500 page), different for prod and dev (Drab.Core)
* explain more how socket works in the documentation
* Drab.Socket steels all `connect` callbacks. Bad Drab

## 0.4.0
Changes:
* Drab.Query.select returns a list of [id: value] instead of [value]

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
* render templates, views in commanders
* render Drab templates in a compile-time
