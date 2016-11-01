# Drab

Query and update browser DOM objects directly from the server side. No javascript programming needed anymore!

## Warning: this software is still experimental!

See [Demo Page](https://tg.pl/drab) for live demo and description.

## Installation

  So far the process of the installation is rather manually, in the future will be automatized.

  1. Add `drab` to your list of dependencies in `mix.exs` in your Phoenix application:

    ```elixir
    def deps do
      [{:drab, git: "https://github.com/grych/drab.git"}]
    end
    ```

  2. Install dependencies:

    ```bash
    mix deps.get
    ```

  3. Install Drab Javascript library (TODO: npm package):

    ```bash
    $ mix drab.install.js

    Created a link to drab.js in web/static/js

    lrwxr-xr-x  1 grych  staff  40  1 lis 23:12 drab.js -> ../../../deps/drab/web/static/js/drab.js
    ```

  4. Add `node-uuid` and `jquery` to `package.json`:

    ```json
    "dependencies": {
      "jquery": ">= 2.1",
      "node-uuid": "~1.4.0"
    }
    ```

  5. Add jQuery as a global at the end of `brunch-config.js`:

    ```javascript
    npm: {globals: {
      $: 'jquery',
      jQuery: 'jquery'
    }}
    ```

  6. And install it:

    ```bash
    npm install && node_modules/brunch/bin/brunch build 
    ```

  7. Initialize `drab.js` by adding the following to `web/static/js/app.js` in your application:

    ```javascript
    import Drab from "./drab"
    let ds = new Drab()
    ```

  8. And to the layout page (`web/templates/layout/app.html.eex`)

    ```html
    <%= Drab.Client.js(@conn) %>
    ```
    
    just before the following line:

    ```html
    <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
    ```
  9. Generate Cipher random keys and append it to `config/dev.exs` (or `config/prod.secret.exs` while deploying on production):

    ```bash
    $ mix drab.gen.cipher dev 
    The following lines were added to your `config/dev.exs`:

    # Configuration of Cipher, required by Drab
    config :cipher, keyphrase:   "QSIMcSGtup9yHt92v0WwdXVikuP1Gu8poZ4HbkRDQSm4kBgDzhc6ezh/pN1e3h/A",
                    ivphrase:    "RvK4eh9mbTn3jkAPVDXToRsy0jrqeRznn+wc3wGqjBMdsKm/fXTNfkYLJFTlhyCb",
                    magic_token: "FRb2qlyE2Z/w01iAxm2/oXsmuVnQRL+OD13RF+ISLh/si1m7fwOWmT+MtOG86kUp"
    ```

  10. Initialize websockets by adding the following to `lib/endpoint.ex`:

    ```elixir
    socket "/drab/socket", Drab.Socket
    ```

  11. Generate the first page Commander (commander is a controller for Drab live page). Commander name should correspond to controller, so PageController should have Page Commander:

    ```bash
    $ mix drab.gen.commander Page
    * creating web/commanders/page_commander.ex

    Add the following line to your Example.PageController:
        use Drab.Controller 
    ```

  11. As described in the previous task, add `Drab.Controller` to your page Controller (eg. `web/controllers/page_controller.ex` in the default app):

    ```elixir
    defmodule Testapp.PageController do
      use Testapp.Web, :controller
      use Drab.Controller 

      def index(conn, _params) do
        render conn, "index.html"
      end
    end    
    ```

  12. Edit the commander created above by `mix drab.gen.commander`, file `web/commanders/page_commander.ex` and add some real action in it:

    ```elixir
    defmodule Testapp.PageCommander do
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

  Finally! Run the phoenix server and enjoy working on the dark side of the web.

## What now?

Visit [Demo Page](https://tg.pl/drab) for live demo and description.

## Contact

(c)2016 Tomek "Grych" Gryszkiewicz, 
<grych@tg.pl>



