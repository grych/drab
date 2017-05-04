## 0.4.0
Changes:

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* broadcast to all except you (really?)
* benchmarks
* dependencies for modules (for ex. Modal depends on Query)
* extract Drab Store and Session to standalone module (loaded by default)
* group JS commands to be launched in one step
* render partials in commanders (accutally it can already be done, must think about some helpers)
* render additional, user templates in a compile-time
* compress Drab templates (js)
* before_handler, only: should take a list or atom (currently list only)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* remove Query from the default, rename it to Drab.JQuery
* new default module, not jQuery based
* execute(:method, params) does not work when the method have more than 1 parameter

## Bugs or features?
* Drab.Socket steals all `connect` callbacks. Bad Drab
