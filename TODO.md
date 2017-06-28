
## 0.5.0
Bugs:

Changes:
* remove Query from the default
* new default module, not jQuery based
* changesets for update/insert in the new base module
* group JS commands to be launched in one step, if possible
* DOM tree as a Map?
* Query must work with Live
* have a values of the <input> fields from parent <form> directly in the Commander Event Handler Function - only if drab-send-params set in button
* re-initiate JS event handler after changing the SPAN (inside it)
* helper to change URL (smart?)

## 0.6.0
Changes:
* support Phoenix 1.3

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* broadcast to all except you (really?)
* benchmarks (compare to AJAX)
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* before_handler (etc), only: should accept a list or atom (currently list only)
* technical socket? for broadcasts from drab server
* cumulate drab related assigns in socket to one map `__drab`

Bugs:
* spawn_link in handler does not terminate the spawned process

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
