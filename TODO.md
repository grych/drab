## 0.3.0
Changes:
* waiter functionality
* before_handler callback (to run before each handler), if return false, do not proceed with 
* after_handler, getting the return value of handler

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
* handling event handler crashes without disconnect the whole socket (spawn instead of spawn_link)
* extract Drab Store and Session to standalone module (loaded by default)
* group commands to be launched in one step
