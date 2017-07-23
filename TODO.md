
## 0.5.0
Bugs:
* insert and innerHTML should re-assing drab events


## 0.5.2
* Live.poke - better error message when partial not found

* Also, instead of 'broadcasting' a change to all browsers, why not do what Phoenix.pubsub does? Allow you to override an outgoing message (then in your time broadcast example you could 'catch' the outgoing message and reformat it?)

* should take Safe in all html related functions
* use MapSet in the live.ex

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
* think if drab_store shouldn't be page or controller/based
* commander per template

Changes:
* group JS commands to be launched in one step, if possible
* re-initiate JS event handler after changing the SPAN (inside it)
* use <%/ %> to not drab the specific one


Bugs:
* spawn_link in handler does not terminate the spawned process

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
