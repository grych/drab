## 0.1.1
Changes:
* added more jQuery methods, like width, position, etc
* cycling
    update(:text, set: ["One", "Two", "Three"], on: "#thebutton")
    update(:class, set: ["btn-success", "btn-danger"], on: "#save_button")
* toggling
    update(:class, toggle: "btn-success", on: "#btn")

Fixes:
* atom leaking issue (#1)
