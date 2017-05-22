(sorry for the mess, this is internal notes file)

### Controller:

use Drab.Live.Controller (injected automatically )

render_live - proxy over render, adding span with id unique identifying the partial (controller + template), sha
musi jakoś oznaczać gdzie interpolować


What about re-rendering the whole page?



### View & Template

use Drab.Live.View (or even Drab.View, to be consistent, Drab.View may inject Drab.Live.View by config)

<%= render_living("parial.html", bindings) %> - sorround with <span>

<%= live(f) %> (could be good to find a shorthand for it)
  --> "{{ f tokenized? }}" - FIND OUT HOWTO
<div class="class-<%= live(@class) %>"><%= @value %></div>

The best would be the possibility to update only one variable, not to bind them all


Attach input to something (jak to zrobic bez state?)

to do an interpolation of {{}} Drab must keep the page on the client side..

<div> under which controller changed ???


helpers:

* live_button
* live_input notify_on: :change, :keyup, :debounce etc

### Commander

rerender("partial.html", bindings) - replace the patrial

replace variable in "partial.html" (live) (( variables MUST be stored in the partial, if we want to update the only one))
replace variable (in the whole document)

find where the @variable is and replace only this tag?

replace all occurences of variable? find it in the actual template?
