## 0.3.0
Changes:
* handling disconnects (callback ondisconnect on server side?)
* handling event handler crashes without disconnect the whole socket (spawn instead of spawn_link)
* event handler continue to work after disconnect (is it a really good idea?)
* Drab.Server to receive messages from the outside world (and broadcast them to the clients)

## 0.4.0
Changes:

## Future
Changes:
* tests, tests, tests
* benchmarks
* debuggin console
* timeout for event handlers
* timeout for Drab.Query and Drab.Modal function
* specify on which pages drab broadcasts, with wildcard
* dependencies for modules (for ex. Modal depends on Query)
* keep Store in a permament location (cookie or browser store) on demand
* before_handler callback (to run before each handler), if return anything else than Socket, do not proceed
