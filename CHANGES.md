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
