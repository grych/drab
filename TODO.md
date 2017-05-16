## 0.4.1
Changes:
* technical socket? for broadcasts from drab server

## 0.5.0
Changes:
* remove Query from the default, rename it to Drab.JQuery
* new default module, not jQuery based
* changesets for update/insert in the new base module
* group JS commands to be launched in one step, if possible
* DOM tree as a Map?

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* broadcast to all except you (really?)
* benchmarks
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* before_handler (etc), only: should accept a list or atom (currently list only)
* dependencies for modules (for ex. Modal depends on Query)


Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
