# CHANGELOG

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][unreleased]

## [v0.7.0] - 2018-01-20
Updated the Drab core to introduce few important features. Fixed to Elixir version `>= 1.5.2`. Tested with Elixir 1.6.0.

### Possibility to provide own `connect/2` callback for socket authentication, etc
Previously, Drab intercepted the `connect/2` callback in your `UserSocket`. Now, there is a possibility to use your own callback:

    defmodule MyApp.UserSocket do
      use Phoenix.Socket

      channel "__drab:*", Drab.Channel

      def connect(params, socket) do
        Drab.Socket.verify(socket, params)
      end
    end

[Do You Want to Know More?](https://hexdocs.pm/drab/Drab.Socket.html#module-method-2-use-your-own-connect-2-callback)

### Use of the custom marker "/" in Drab templates
This version allow you to use of `<%/ %>` marker to avoid using `Drab.Live` for a given expression. The expression would be treaten as a normal Phoenix one, so will be displayed in rendered html, but Drab will have no access to it.

```html
<div>
  <%/ @this_assigns_will_be_displayed_but_not_drabbed %>
</div>
```

[Do You Want to Know More?](https://hexdocs.pm/drab/Drab.Live.html#module-avoiding-using-drab)

### Changed event definition core
The existing syntax `drab-event` and `drab-handler` attributes does not allow having multiple events on the one DOM object (#73). This form is now depreciated and replaces with the brand new, better syntax of:

    <tag drab="event:handler">

Now may set more event on the single object:

    <input drab="focus:input_focus blur:input_blur"

or:

    <input drab-focus="input_focus" drab-blur="input_blur">

[Do You Want to Know More?](https://hexdocs.pm/drab/Drab.Core.html#module-events)

### Event shorthands list is now configurable
By default, you can use only few arbitrary-chosen shorthands for the event name / handler name (`drab-click="clicked"`) attribute. Now you may configure the list with `:events_shorthands` config.
See #73.

### Style changes:
* source code formatted with 1.6.0
* use `@impl true` in behaviour callbacks
* started annotating all functions with `@spec` (so far only few)
* small style improvements suggested by Credo

### Depreciations:
* `Drab.Client.js/2` becomes `Drab.Client.run/2`
* `drab-event` and `drab-handler` attributes combination replaced by `drab`

## [v0.6.3]
Changes:
* workaround for #71: better docs and error message
* `Drab.Live.poke` returns {:error, description} on error
* improved examples on connect in iex (#72)
* assign list with `Drab.Live.assigns` (#72)


## [v0.6.2]
Bug fixes:
* live_helper_modules config entry now allows list (#66)
* when updating `value` attribute, `poke` updates property as well (for inputs and textareas)
* changed the order of loaded modules; fixes #69
* changed the way drab is asking for a store and session on connect; probably fixed #68


## [v0.6.1]
This release fixes new, better bugs introduced in v0.6.0:
* "atom :save_assigns not found" error
* `@conn` case (it was not removing @conn from the initial)
* cache file was deleted after `mix phx.digest`, moved the file to the Drab's priv directory

### Please read documentation for `Drab.Browser`, the API has changed
* cleaned up the mess with API in `Drab.Browser`

## [v0.6.0]
This is a major release. The biggest change is completely redesigned engine for `Drab.Live` with `nodrab` option. Also introducting **shared commanders**, updates in `Drab.Browser`, performance and bug fixes.

### Migration from 0.5

After installation, please remove all remaining `priv/hashes_expressions.drab.cache.*` files (they were renamed to `drab.live.cache`) and do a mix clean to recompile templates:

````shell
mix clean
````

### Drab.Live
The main change in the new template engine is that now it is not injecting `<span>` everywhere. Now, it parses the html and tries to find the sourrounding tag and mark it with the attribute called `drab-ampere`. The attribute value is a hash of the previous buffer and the expression, so it is considered unique.

Consider the template, with initial value of `1` (given in render function in the Controller, as usual):

````html
<p>Chapter <%= @chapter_no %>.</p>
````
which renders to:

````html
<p drab-ampere="someid">Chapter 1.</p>
````

This `drab-ampere` attribute is injected automatically by `Drab.Live.EExEngine`. Updating the `@chapter_no` assign in the Drab Commander, by using `poke/2`:

````elixir
chapter = peek(socket, :chapter_no)     # get the current value of `@chapter_no`
poke(socket, chapter_no: chapter + 1)   # push the new value to the browser
````

will change the `innerHTML` of the `<p drab-ampere="someid">` to "Chapter 2." by executing the following JS on the browser:

````javascript
document.querySelector('[drab-ampere=someid]').innerHTML = "Chapter 2."
````

This is possible because during the compile phase, Drab stores the `drab-ampere` and the corresponding pattern in the cache DETS file (located in `priv/drab.live.cache`).

#### Sometimes it must add a `<span>`

In case, when Drab can't find the parent tag, it injects `<span>` in the generated html. For example, template
like:

````html
Chapter <%= @chapter_no %>.
````

renders to:

````html
Chapter <span drab-ampere="someid">1</span>.
````

#### Avoiding using Drab (`nodrab` option)
If there is no need to use Drab with some expression, you may mark it with `nodrab/1` function. Such expressions will be treated as a "normal" Phoenix expressions and will not be updatable by `poke/2`.

````html
<p>Chapter <%= nodrab(@chapter_no) %>.</p>
````

In the future (Elixir 1.6 I suppose), the `nodrab` keyword will be replaced by a special EEx mark `/` (expression
will look like `<%/ @chapter_no %>`).

#### The `@conn` case
The `@conn` assign is often used in Phoenix templates. Drab considers it read-only, you can not update it
with `poke/2`. And, because it is often quite hudge, may significantly increase the number of data sent to
the browser. This is why Drab treats all expressions with only one assign, which happen to be `@conn`, as
a `nodrab` assign.

### Shared Commanders
By default Drab runs the event handler in the commander module corresponding to the controller, which rendered the current page. Now it is possible to choose the module by simply provide the full path to the commander:

````html
<button drab-click='MyAppWeb.MyCommander.button_clicked'>clickme</button>
````

Notice that the module must be a commander module, ie. it must be marked with `use Drab.Commander`, and the function must be whitelisted with `Drab.Commander.public/1` macro.

### Changes in `Drab.Browser`
All function in `Drab.Browser` were renamed to their bang version. This is because in the future release functions with and without bang will be more consist with Elixir standards - nobang function will return tuples, bangs will raise on error.

### Warning: functions redirect_to!/2 and console!/2 are changed
In preparation to change all the functions in the module, this functions behavior have changed. Now, they are just bang version of the "normal" function, and **they are not broadcasting anymore**.

You should use `broadcast_redirect_to!/2` and `broadcast_console!/2` instead.


## v0.5.6
Reverted back #51 - `@conn` is available again.

## v0.5.5

### Fixes:
* #20 (broadcasting in Phx 1.3)
* #44 (docs for broadcasting)
* #45 (button inside for submits in Firefox)
* #47 (docs and error message updated)
* #51 (removed @conn from living assigns, encrypts assigns)


## v0.5.4
Fixes for adding templates in a runtime.

```elixir
poke socket, live_partial1: render_to_string("partial1.html", color: "#aaaabb")
poke socket, "partial1.html", color: "red"
```

### Fixes:
* #37
* #40 (updated documentation for Drab.Live.EExEngine)
* #41
* #34 and #38

## v0.5.3
Phoenix 1.3 compatibility
* bugfixes (#19, #36).
* `drab.gen.commander` works both with Phoenix 1.2 and 1.3


## v0.5.2
This is a small update to make Drab compatible with Elixir 1.5.
Due to an issue with 1.5.0 (elixir-lang/elixir#6391) Elixir version is fixed on 1.4 or >= 1.5.1.

### Fixes:
* #26, #27, #30, #31, #33


## v0.5.1
### Fixes:
* Transpiled all JS templates, and removed all occurences of `forEach` (#22)
* Radio buttons not reported correctly in `sender["form"]` (#23)
* New `:main_phoenix_app` config item, in case the app name can't be read from `mix.exs` (#25)

### Changes:
* `sender[:params]` contains params normalized to controller type params (#24)

      %{"_csrf" =>
      "1234", "user[id]" => "42", "user[email]" => "test@test.com",
      "user[account][id]" => "99", "user[account][address][street]" =>
      "123 Any Street"}

    becomes:

      %{"_csrf" => "1234",
      "user" => %{"account" => %{"address" => %{"street" => "123 Any Street"},
      "id" => "99"}, "email" => "test@test.com", "id" => "42"}}

### New features:
* `Core.Browser.set_url/2` to manipulate the browser's URL bar

## v0.5.0
***This version is a major update***. The default module, `Drab.Query` has been replaced with `Drab.Live` and `Drab.Element`. Drab is not jQuery dependent by default anymore.

### `Drab.Live`
Allows to remotely (from the server side) replace the value of the assign in the displayed paged, without re-rendering and reloading the page.

Such template:

```html
<a href="https://<%= @url%>" @style.backgroundColor=<%= @color%>>
  <%= @url %>
</a>
```

can be updates live with `poke/2`:

```elixir
poke socket, url: "tg.pl/drab", color: "red"
```

### `Drab.Element`
Query and update displayed page from the server side.

```elixir
set_prop socket, "p", style: %{"backgroundColor" => "red"} # awesome effect
```

### Broadcasting
Broadcasting functions now get `subject` instead of `socket`. There is no need to have an active socket to broadcast anymore. Useful when broadcasting from background servers or `ondisconnect` callback.

### Form parameters in sender
If the event launching element is inside a `<FORM>`, it gets a values of all input elements within that form. This is a map, where keys are the element's `name` or `id`.

### Upgrading from 0.4
Add `Drab.Query` and `Drab.Modal` to your commanders:

```elixir
use Drab.Commander, module: [Drab.Query, Drab.Modal]
```

### Depreciations
All soft depreciations up to 0.4.1 became hard.

## v0.4.1 - 2017-05-25

### New:
* `render_to_string/2` in Commander, a shorthand for `Phoenix.View.render_to_string/3`

### Internal improvements:
* removed jQuery from core JS code; only Drab.Query and Drab.Modal depends on jQuery
* module dependencies (Drab behaviour)

## 0.4.0
Changes:

* renamed `execjs/2` -> `exec_js/3`, `brodcastjs/2` -> `broadcast_js/3`
* `exec_js/3` returns tuple {:ok, result} or {:error, reason}
* `exec_js!/3` raises exceptions on JS error
* configurable timeouts for `exec_js/3` and `exec_js!/3`


## 0.3.5
Changes:
* Drab.Browser with browser related functions, like local time, timezone difference, userAgent, redirect_to

Depreciations:
* Drab.Core.console moved to Drab.Browser

## 0.3.4 (2017-05-04)

Bug fixes:

* `execute!` allows string as the method with parameters
* reverted back the timeout for `execjs/2` - it caused troubles and it is not really needed; in case of the
  connectivity failure the whole Drab will die anyway

## 0.3.3 (2017-05-03)

* precompile Drab templates for better performance; user templates are still interpreted on the fly
* choose the behaviour for broadcasting functions: now may send to `:same_url`, `:same_controller` or to user
  defined `"topic"`
* timeout for `execjs/2` (and so for the most of Drab.Query functions); default is 5000 ms and can be changed
  with `config :drab, timeout: xxx|:infinity`

## 0.3.2

* phoenix version ~> 1.2 (#13)
* warning when user updates `attr: "data-*"` - it should be done with `data: *` (#14)
* integration tests

## 0.3.1

### New features:

* debugging Drab functions directly from `IEx` console
* display information when handler die, different for prod and dev


## 0.3.0

### API Changes and Depreciations:

* Drab.Query.select API changed: now `select(:val)` returns first value instead of the list, but all jQuery methods
  have corresponding plural methods, which return a Map of `%{name|id|__undefined_XX => value}`

````elixir
# <span name="first_span" class="qs_2 small-border">First span with class qs_2</span>
# <span id="second_span" class="qs_2 small-border">Second span with class qs_2</span>
socket |> select(:html, from: ".qs_2")
# "First span with class qs_2"
socket |> select(:htmls, from: ".qs_2")
# %{"first_span" => "First span with class qs_2", "second_span" => "Second span with class qs_2"}
````

* depreciated `Drab.Endpoint`; Drab now injects in the `UserSocket` with `use Drab.Socket` (#8). Now
  it is possible to share Drab socket with your code (create your channels)

* moved Commander setup to macros instead of use options

````elixir
use Drab.Commander
onload :page_loaded
access_session :userid
````

* renamed JS `launch_event()` to `run_handler()`

### New features:

* `Drab.Waiter` module adds ability to wait for an user response in your function, so you can have a reply
  and continue processing.

````elixir
return = waiter(socket) do
  on "selector1", "event_name1", fn (sender) ->
    # run when this event is triggered on selector1
  end
  on "selector2", "event_name2", fn (sender) ->
    # run when that event is triggered on selector2
  end
  on_timeout 5000, fn ->
    # run after timeout, default: infinity
  end
end
````

* `before_handler` callback (to run before each handler); do not process the even handler if `before_handler`
  returns nil or false

````elixir
before_handler :check_login, except: [:log_in]
def check_login(socket, _dom_sender) do
  get_session(socket, :userid)
end
````

* `after_handler`, getting the return value of handler as an argument

````
after_handler :clean_up
def clean_up(_socket, _dom_sender, handler_return) do
  # some clieanup
end
````

* `Drab.Query.select(:all)` - returns a map of return values of all known jQuery methods

````elixir
socket |> select(:all, from: "span")
%{"first_span" => %{"height" => 16, "html" => "First span with class qs_2", "innerHeight" => 20, ...
````

## 0.2.6
Changes:
* reload drab events in JS after each insert or update
* added event object with specified properties to the dom_sender
* added `debounce` function as an option to the event handler
* renamed Drab.Config to Drab.Commander.Config

## 0.2.5
Changes:
* handling disconnects (ondisconnect callback)
* keep Store in a permament location (browser store) on demand
* access to Plug Session with `Drab.Core.get_session/2`

## 0.2.4
Fixed:
* not working in IE11 (#5)

## 0.2.3
Fixed:
* not working on iOS9 (#3): changed all ES6 constructs to plain JS

## 0.2.2
New callbacks and Session housekeeping (renamed to Store)

Changes:
* new callback: onconnect
* renamed Session to Store to avoid confusion

## 0.2.1
Introduced Drab Session: the way to access (read-only) the Plug Session map in the Commander.

Changes:
* `use Drab.Endpoint` instead of `socket Drab.config.socket, Drab.Socket` in endpoint.ex
* Drab Session with value inheritance from the Plug Session
* event handler must return socket, warning in the other case

Fixes:
* security (#2): checks token in each event call to prevent tampering


## 0.2.0 (2017-01-22)
This version cames with refactored modules and client JS library. It is now modular, so you don't need
to use jQuery and DOM if you don't have to.

Changes:
* extracted Drab core; split the JS templates between modules
* jQuery not required in Drab.Core
* moved Drab.Query.execjs and broadcastjs to Drab.Core.execjs and broadcastjs
* moved Drab.Call.console to Drab.Core.console (and console!)
* renamed Drab.Call to Drab.Modal
* renamed Drab.Templates to Drab.Template
* JS: Drab is global, Drab.launch_event() is available


## 0.1.1

Changes:
* added more jQuery methods, like width, position, etc
* cycling
    update(:text, set: ["One", "Two", "Three"], on: "#thebutton")
    update(:class, set: ["btn-success", "btn-danger"], on: "#save_button")
* toggling class
    update(:class, toggle: "btn-success", on: "#btn")

Fixes:
* atom leaking issue (#1)


## 0.1.0
First public version. Very shy.
