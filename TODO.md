
# v0.6.0
* Elixir 1.6 and Phoenix 1.3
* use <%/ %> to not drab the specific one
* remove depreciations

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
* Also, instead of 'broadcasting' a change to all browsers, why not do what Phoenix.pubsub does? Allow you to override an outgoing message (then in your time broadcast example you could 'catch' the outgoing message and reformat it?)
* should take Safe in all html related functions
* use MapSet in the live.ex

Changes:
* group JS commands to be launched in one step, if possible
* re-initiate JS event handler after changing the SPAN (inside it)

Bugs:
* spawn_link in handler does not terminate the spawned process

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
