## v0.8.0
* depreciate undeclared handlers

## Bugs:

## Future
Changes:
* optimistic updates
* consider DynamicSupervisor as a replacement for Drab GenServer
* check token on each incoming message
* is controller, action and assigns neccasary in drab token on page generation?
* security concerns when onload
* check if the handler exists in a compile time
* benchmarks (compare to AJAX)
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* before_handler (etc), only: should accept a list or atom (currently list only)
* think if drab_store shouldn't be page or controller/based
* Also, instead of 'broadcasting' a change to all browsers, why not do what Phoenix.pubsub does? Allow you to override an outgoing message (then in your time broadcast example you could 'catch' the outgoing message and reformat it?)
* should take Safe in all html related functions
* [elixir 1.7] change deppie to @deprecated and @since
* test broadcasting

Changes:
* group JS commands to be launched in one step, if possible
* re-initiate JS event handler after changing the SPAN (inside it)

Bugs:
* exec_elixir should be able to take any argument, not only a map

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)

