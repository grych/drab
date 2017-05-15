[![phoenix logo](https://raw.githubusercontent.com/grych/drab-poc/master/web/static/assets/images/drab-banner.png)](https://tg.pl/drab)

[![hex.pm version](https://img.shields.io/hexpm/v/drab.svg)](https://hex.pm/packages/drab)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/drab.svg?style=flat)](https://hex.pm/packages/drab)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/drab/)

### See [Demo Page](https://tg.pl/drab) for live demo and description.

Drab - Access the browser User Interface from the Server Side. No Javascript programming needed anymore!

Drab extends Phoenix Framework to "remote control" UI on the browser, live. The idea is to move all User Interface
logic to the server-side, to eliminate Javascript and Ajax calls.

## Teaser

* Client side:

```html
<div class="progress">
  <div class="progress-bar" role="progressbar" style="width:0%">
  </div>
</div>
<button drab-click="perform_long_process">Click to start processing</button>
```

* Server side:

```elixir
def perform_long_process(socket, dom_sender) do
  steps = MyLongProcess.number_of_steps()
  for i <- 1..steps do
    MyLongProcess.perform_step(i)
    # update the progress bar after each of MyLongProcess steps
    socket 
      |> update(
          css: "width", 
          set: "#{i * 100 / steps}%", 
          on: ".progress-bar")
      |> update(
          :html,         
          set: "#{Float.round(i * 100 / steps, 2)}%", 
          on: ".progress-bar")
  end
  socket |> insert(class: "progress-bar-success", into: ".progress-bar")
end
```

## Warning: this software is still experimental!

### Prerequisites

  1. Erlang ~> 19

  2. Elixir ~> 1.3

  3. Phoenix ~> 1.2

## Installation

  So far the process of the installation is rather manually, in the future will be automatized.

  1. Add `drab` to your list of dependencies in `mix.exs` in your Phoenix application and install it:

```elixir
def deps do
  [{:drab, "~> 0.3"}]
end
```

```bash
$ mix deps.get
$ mix compile
```

  2. Add `jquery` and `boostrap` to `package.json`:

```json
"dependencies": {
  "jquery": ">= 3.1.1",
  "bootstrap": "~3.3.7"
}
```

  You may ommit this step if you are not planning to use DOM, jQuery, Drab.Query and Drab.Modal -
  [see Domless Drab](https://tg.pl/drab/nojquery)

  3. Add jQuery as a global at the end of `brunch-config.js`:

```javascript
npm: {globals: {
  $: 'jquery',
  jQuery: 'jquery',
  bootstrap: 'bootstrap'
}}
```

  You may ommit this step if you are not planning to use DOM, jQuery, Drab.Query and Drab.Modal -
  [see Domless Drab](https://tg.pl/drab/nojquery)

  4. And install it:

```bash
$ npm install && node_modules/brunch/bin/brunch build 
```

  5. Initialize Drab client library by adding to the layout page (`web/templates/layout/app.html.eex`)

```html
<%= Drab.Client.js(@conn) %>
```
    
    just after the following line:

```html
<script src="<%= static_path(@conn, "/js/app.js") %>"></script>
```
    
  6. Initialize Drab sockets by adding the following to `web/channels/user_socket.ex`:

```elixir
use Drab.Socket
```

Congratullations! You have installed Drab and you can proceed with your own Commanders.

## Usage

All the Drab functions (callbacks, event handlers) are placed in the module called `Commander`. 
Think about it as a controller for the live pages. Commanders should be placed in `web/commanders` directory.

To enable Drab on the specific pages, you need to add the directive `use Drab.Controller` to your application 
controller. 

Remember the difference: `controller` renders the page while `commander` works on the live page.

  1. Generate the page Commander. Commander name should correspond to controller, so PageController should have 
  PageCommander:

```bash
$ mix drab.gen.commander Page
* creating web/commanders/page_commander.ex

Add the following line to your Example.PageController:
    use Drab.Controller 
```

  2. As described in the previous task, add `Drab.Controller` to your page Controller 
  (eg. `web/controllers/page_controller.ex` in the default app):

```elixir
defmodule DrabExample.PageController do
  use Example.Web, :controller
  use Drab.Controller 

  def index(conn, _params) do
    render conn, "index.html"
  end
end    
```

  3. Edit the commander file `web/commanders/page_commander.ex` and add some real action - the `onload` callback 
  which fires when the browser connects to Drab.

```elixir
defmodule DrabExample.PageCommander do
  use Drab.Commander

  onload :page_loaded

  # Drab Callbacks
  def page_loaded(socket) do
    socket 
      |> update(:html, set: "Welcome to Phoenix+Drab!", on: "div.jumbotron h2")
      |> update(:html, 
          set: "Please visit <a href='https://tg.pl/drab'>Drab</a> page for more examples and description",
          on:  "div.jumbotron p.lead")
  end
end
```

Function `update/3` (shorthand for `Drab.Query.update/3`) with `:html` parameter sets the HTML of DOM object, 
analogically to `$().html()` on the client side.

Finally! Run the phoenix server and enjoy working on the Dark Side of the web.

### All above is available for download [here](https://github.com/grych/drab-example)

## Drab Events

* Client-side: assign the events directly in HTML, using `drab-event=event_name` and `drab-handler='event_handler'` 
combination of attributes, when `event_name` is the JS event name and `event_handler` is the function name 
in the Commander. This function will be fired on event. There is also a shorthand for this: 
`drab-[event_name]=event_handler` (currently: click, change, keyup, keydown are defined). Example:

```html
<button drab-click='button_clicked'>Clickme!</button>
```

* Server-side: when clicked, this button will launch the following action on the corresponding commander:

```elixir
defmodule Example.PageCommander do
  use Drab.Commander

  # Drab Events
  def button_clicked(socket, dom_sender) do
    socket 
      |> update(:text, set: "alread clicked", on: this(dom_sender))
  end
end
```

As you probably guess, this changes button description (`Drab.Query.update/3` used with `:text`).

## What now?

Visit [Demo Page](https://tg.pl/drab) for a live demo and more description.

Visit [Docs with Examples](https://tg.pl/drab/docs) - documentation with short examples.

# Tests and Sandbox

Since 0.3.2, Drab is equipped with its own Phoenix Server for automatic integration tests and for sandboxing and play
with it.

## Sandbox

* clone Drab from github:

````shell
git clone git@github.com:grych/drab.git
cd drab
````

* get deps and node modules:

````shell
mix deps.get
npm install && node_modules/brunch/bin/brunch build
````

* start Phoenix with Drab:

````shell
iex -S mix phoenix.server
````

* open the browser and navigate to http://localhost:4000

* follow the instructions in IEx to play with Drab functions:

````elixir
import Drab.Core; import Drab.Query; import Drab.Modal; import Drab.Waiter
socket = Drab.get_socket(pid("0.443.0"))

iex(5)> socket |> alert("Title", "WOW!")                                          
{:ok, %{}}
iex(6)> socket |> select(:text, from: "h3")
"Drab Tests"
iex(7)> socket |> update(:text, set: "It is set from IEx, wow!", on: "h3")  
%Phoenix.Socket{assigns: %{__action: :index, .........
````

## Tests

Most of the Drab tests are integration (end-to-end) tests, thus they require automated browser. Drab uses 
`chromedriver`, which must be run while you run tests.

* clone Drab from github:

````shell
git clone git@github.com:grych/drab.git
cd drab
````

* get deps and node modules:

````shell
mix deps.get
npm install && node_modules/brunch/bin/brunch build
````

* run `chromedriver` 

* run tests:

````shell
$ mix test
Compiling 29 files (.ex)

Generated drab app
.......................................................................

Finished in 149.4 seconds
71 tests, 0 failures

Randomized with seed 277485
````

## Contact

(c)2016 Tomek "Grych" Gryszkiewicz, 
<grych@tg.pl>


Illustrations by https://www.vecteezy.com


