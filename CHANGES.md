## 0.3.0
API Changes and Depreciations:
* depreciated `Drab.Endpoint`; Drab now injects in the `UserSocket` with `use Drab.Socket` (#8). Now 
it is possible to share Drab socket with your code (create your channels)

* moved Commander setup to macros instead of use options

````
use Drab.Commander
onload :page_loaded
access_session :userid
````

* renamed JS `launch_event()` to `run_handler()`

New features:
* `before_handler` callback (to run before each handler); do not process the even handler if
  `before_handler` returns nil or false

````
before_handler :check_login, except: [:log_in]
def check_login(socket, _dom_sender) do
  get_session(socket, :userid)
end
````

* after_handler, getting the return value of handler as an argument

````
after_handler :clean_up
def clean_up(_socket, _dom_sender, handler_return) do
  # some clieanup
end
````

* `Drab.Query.select(:all)` - returns a map of return values of all known jQuery methods

````
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
