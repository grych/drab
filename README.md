# Drab

Query and update browser DOM objects directly from the server side. No javascript programming needed anymore!

## Warning: this software is still experimental!

See [Demo Page](https://tg.pl/drab) to live demo and description.

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

  3. Install Drab Javascript library (TODO: to be done as npm package):

    ```bash
    ln -s deps/drab/web/static/js/drab.js web/static/js/drab.js
    ```

  4. Initialize `drab.js` by adding the following to `app.js` in your application:

    ```javascript
    import Drab from "./drab"
    let ds = new Drab()
    ```



