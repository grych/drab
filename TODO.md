## 0.3.6
Changes:
* render partials in commanders (accutally it can already be done, just add a helper)
* before_handler, only: should take a list or atom (currently list only)
* dependencies for modules (for ex. Modal depends on Query)
* execute(:method, params) does not work when the method have more than 1 parameter
* execute(method: [parameters]) should work

## 0.4.0
Changes:
* timeouts
* execjs and broadcastjs returns tuple {:ok, } or {:error, }
* execjs! and broadcastjs! raise on JS error

## 0.5.0
Changes:
* remove Query from the default, rename it to Drab.JQuery
* new default module, not jQuery based
* changesets for update/insert in the new base module
* group JS commands to be launched in one step, if possible

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* broadcast to all except you (really?)
* benchmarks
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
