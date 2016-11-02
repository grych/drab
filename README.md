# Drab

Manipulate browser DOM objects directly from Elixir. No javascript programming needed anymore!

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
          |> attr(".progress-bar", "style", "width: #{i * 100 / steps}%")
          |> html(".progress-bar", "#{Float.round(i * 100 / steps, 2)}%")
      end
      add_class(socket, ".progress-bar", "progress-bar-success")

      {socket, dom_sender}
    end
    ```

## Warning: this software is still experimental!

### See [Proof of Concept Page](https://tg.pl/drab) for live demo and description.

## Installation

  So far the process of the installation is rather manually, in the future will be automatized.

  1. Add `drab` to your list of dependencies in `mix.exs` in your Phoenix application and install it:

    ```elixir
    def deps do
      [{:drab, git: "https://github.com/grych/drab.git"}]
    end
    ```

    ```bash
    $ mix deps.get
    $ mix compile
    ```

  2. Install Drab Javascript library (TODO: npm package):

    ```shell
    $ mix drab.install.js
    Created a link to drab.js in web/static/js
    lrwxr-xr-x  1 grych  staff  40  1 lis 23:12 drab.js -> ../../../deps/drab/web/static/js/drab.js
    ```

  3. Add `node-uuid` and `jquery` to `package.json`:

    ```json
    "dependencies": {
      "jquery": ">= 2.1",
      "node-uuid": "~1.4.0"
    }
    ```

  4. Add jQuery as a global at the end of `brunch-config.js`:

    ```javascript
    npm: {globals: {
      $: 'jquery',
      jQuery: 'jquery'
    }}
    ```

  5. And install it:

    ```bash
    $ npm install && node_modules/brunch/bin/brunch build 
    ```

  6. Initialize Drab client library by adding to the layout page (`web/templates/layout/app.html.eex`)

    ```html
    <%= Drab.Client.js(@conn) %>
    ```
    
    just after the following line:

    ```html
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    ```
    
  7. Initialize websockets by adding the following to `lib/endpoint.ex`:

    ```elixir
    socket "/drab/socket", Drab.Socket
    ```

Congratullations! You have Drab installed and you can proceed with your own Commanders.

## Usage

All the Drab functions (callbacks, event handlers) are placed in the module called `Commander`. Think about it as a controller for the live pages. Commanders are similar to Phoenix controllers and should be placed in `web/commanders` directory.

To enable Drab on the specific pages, you need to add the directive `use Drab.Controller` to your application controller. Notice that it will enable Drab on all the pages under the specific controller.

Remember the difference: `controller` renders the page while `commander` works on the live page.

  1. Generate the page Commander. Commander name should correspond to controller, so PageController should have PageCommander:

    ```bash
    $ mix drab.gen.commander Page
    * creating web/commanders/page_commander.ex

    Add the following line to your Example.PageController:
        use Drab.Controller 
    ```

  2. As described in the previous task, add `Drab.Controller` to your page Controller (eg. `web/controllers/page_controller.ex` in the default app):

    ```elixir
    defmodule DrabExample.PageController do
      use Example.Web, :controller
      use Drab.Controller 

      def index(conn, _params) do
        render conn, "index.html"
      end
    end    
    ```

  3. Edit the commander created above by `mix drab.gen.commander`, file `web/commanders/page_commander.ex` and add some real action - the `onload` callback which fires when the browser connects to Drab.

    ```elixir
    defmodule DrabExample.PageCommander do
      use Drab.Commander, onload: :page_loaded

      # Drab Callbacks
      def page_loaded(socket) do
        socket 
          |> html("div.jumbotron h2", "Welcome to Phoenix+Drab!")
          |> html("div.jumbotron p.lead", 
                  "Please visit <a href='https://tg.pl/drab'>Drab Proof-of-Concept</a> page for more examples and description")
      end
    end
    ```

Function `html/3` (shorthand for `Drab.Query.html/3`) sets the HTML of DOM object, analogically to `$().html()` on the client side.

Finally! Run the phoenix server and enjoy working on the dark side of the web.

### The code above is available for download [here](https://github.com/grych/drab-example)

## Drab Callbacks

Currently there is the only one callback, `onload`. You need to set it up with `use Drab.Commander` directive.

## Drab Events

With Drab, you assign the events directly in HTML, using `drab-[event]='event_handler'` attribute, when `event` is the event name (currently: click, change, keyup, keydown) and `event_handler` is the function name in the Commander. This function will be fired on event. Example:

    ```html
    <button drab-click='button_clicked'>Clickme!</button>
    ```

When clicked, this button will launch the following action on the corresponding commander:

    ```elixir
    defmodule Example.PageCommander do
      use Drab.Commander

      # Drab Events
      def button_clicked(socket, dom_sender) do
        socket 
          |> text(this(dom_sender), "alread clicked")
          |> prop(this(dom_sender), "disabled", true)
      end
    end
    ```

As you probably guess, this changes button description (`Drab.Query.text/3`) and disables it (`Drab.Query.prop/4`).

## What now?

Visit [Demo Page](https://tg.pl/drab) for a live demo and more description.

## Contact

(c)2016 Tomek "Grych" Gryszkiewicz, 
<grych@tg.pl>



