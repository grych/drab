## 0.2.6
Changes:
* extract Drab Store and Session to standalone module (loaded by default)
* add event to the dom_sender
* add throttle event:
export function throttle(f, delay){
  var timer = null
  return function(){
    let context = this, args = arguments
    clearTimeout(timer)
    timer = window.setTimeout(() => {
      f.apply(context, args)
    },
    delay || 500)
  }
}
* reload drab events in JS after insert or update
* assigns with __


## 0.3.0
Changes:
* wait_for functionality

## 0.4.0
Changes:

## Future
Changes:
* tests, tests, tests
* benchmarks
* debuggin console
* timeout for event handlers
* timeout for Drab.Query and Drab.Modal functions
* specify on which pages drab broadcasts, with wildcard
* dependencies for modules (for ex. Modal depends on Query)
* before_handler callback (to run before each handler), if return anything else than Socket, do not proceed
* handling event handler crashes without disconnect the whole socket (spawn instead of spawn_link)
* Events https://elixirforum.com/t/drab-phoenix-library-for-server-side-dom-access-released-0-1-0/3277/26
