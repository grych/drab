# CHANGELOG

# v0.5.4
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

# v0.5.3
Phoenix 1.3 compatibility
* bugfixes (#19, #36).
* `drab.gen.commander` works both with Phoenix 1.2 and 1.3


# v0.5.2
This is a small update to make Drab compatible with Elixir 1.5. 
Due to an issue with 1.5.0 (elixir-lang/elixir#6391) Elixir version is fixed on 1.4 or >= 1.5.1.

### Fixes:
* #26, #27, #30, #31, #33


# v0.5.1
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

# v0.5.0
***This version is a major update***. The default module, `Drab.Query` has been replaced with `Drab.Live` and `Drab.Element`. Drab is not jQuery dependent by default anymore.

## New modules

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

## Broadcasting
Broadcasting functions now get `subject` instead of `socket`. There is no need to have an active socket to broadcast anymore. Useful when broadcasting from background servers or `ondisconnect` callback.

## Form parameters in sender
If the event launching element is inside a `<FORM>`, it gets a values of all input elements within that form. This is a map, where keys are the element's `name` or `id`.

## Upgrading from 0.4
Add `Drab.Query` and `Drab.Modal` to your commanders:

```elixir
use Drab.Commander, module: [Drab.Query, Drab.Modal]
```

## Depreciations
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
