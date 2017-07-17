
## 0.5.0
Bugs:
* insert and innerHTML should re-assing drab events
* think if drab_store shouldn't be page or controller/based


## 0.5.1


## 0.6.0
Changes:
* support Phoenix 1.3

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* benchmarks (compare to AJAX)
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* before_handler (etc), only: should accept a list or atom (currently list only)
* cumulate drab related assigns in socket to one map `__drab`

Changes:
* group JS commands to be launched in one step, if possible
* re-initiate JS event handler after changing the SPAN (inside it)
* helper to change URL (smart?)
* use <%/ %> to not drab the specific one

Bugs:
* spawn_link in handler does not terminate the spawned process

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
