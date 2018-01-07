
## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* is `use Drab.Commander` really necessary?
* <p drab-commander>
* check token on each incoming message
* is controller, action and assigns neccasary in drab token on page generation?
* security concerns when onload
* topic, authorization and authentication
* check if the handler exists in a compile time
* @impl
* benchmarks (compare to AJAX)
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)
* before_handler (etc), only: should accept a list or atom (currently list only)
* cumulate drab related assigns in socket to one map `__drab`
* think if drab_store shouldn't be page or controller/based
* Also, instead of 'broadcasting' a change to all browsers, why not do what Phoenix.pubsub does? Allow you to override an outgoing message (then in your time broadcast example you could 'catch' the outgoing message and reformat it?)
* should take Safe in all html related functions
* use <%/ %> to not drab the specific one

Changes:
* group JS commands to be launched in one step, if possible
* re-initiate JS event handler after changing the SPAN (inside it)

Bugs:
* exec_elixir should be able to take any argument, not only a map
* spawn_link in handler does not terminate the spawned process

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)


Drab.Live:

      <%= for u <- @users do %>
        <%= if u != @user do %>
          <%= u %> <br>
        <% end %>
      <% end %>

poking @users AND @user in the same time should only update the parent
