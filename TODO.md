

Drab.Store.save_session issue
should not continue after issue :onconnect

def handle_cast({:onconnect, socket}, %Drab{commander: commander} = state) do
<!-- 16:49:13.702 [error] GenServer #PID<0.694.0> terminating
** (stop) exited in: Task.await(%Task{owner: #PID<0.694.0>, pid: #PID<0.696.0>, ref: #Reference<0.0.1.4964>}, 5000)
    ** (EXIT) time out
    (elixir) lib/task.ex:416: Task.await/2
    (elixir) lib/enum.ex:645: Enum."-each/2-lists^foreach/1-0-"/2
    (elixir) lib/enum.ex:645: Enum.each/2
    lib/drab.ex:136: Drab.handle_cast/2
    (stdlib) gen_server.erl:601: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:667: :gen_server.handle_msg/5
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: {:"$gen_cast", {:onconnect, %Phoenix.Socket{assigns: %{__action: :index, __broadcast_topic: "same_url:/drab", __controller: DrabPoc.PageControll
er, __drab_pid: #PID<0.694.0>, any_other: "test", user_id: 4}, channel: Drab.Channel, channel_pid: #PID<0.693.0>, endpoint: DrabPoc.Endpoint, handler: DrabPoc
.UserSocket, id: nil, joined: true, pubsub_server: DrabPoc.PubSub, ref: "1631", serializer: Phoenix.Transports.WebSocketSerializer, topic: "__drab:same_url:/drab", transport: Phoenix.Transports.WebSocket, transport_name: :websocket, transport_pid: #PID<0.377.0>}}}
State: %Drab{commander: DrabPoc.PageCommander, session: %{}, socket: %Phoenix.Socket{assigns: %{__action: :index, __broadcast_topic: "same_url:/drab", __controller: DrabPoc.PageController, __drab_pid: #PID<0.694.0>, any_other: "test", user_id: 4}, channel: Drab.Channel, channel_pid: #PID<0.693.0>, endpoint: DrabPoc.Endpoint, handler: DrabPoc.UserSocket, id: nil, joined: true, pubsub_server: DrabPoc.PubSub, ref: "1631", serializer: Phoenix.Transports.WebSocketSerializer, topic: "__drab:same_url:/drab", transport: Phoenix.Transports.WebSocket, transport_name: :websocket, transport_pid: #PID<0.377.0>}, store: %{}}
16:49:14.745 [info] JOIN __drab:same_url:/drab to Drab.Channel
 -->  


## 0.4.0
Changes:

* timeouts
* execjs and broadcastjs returns tuple {:ok, } or {:error, }
* execjs! and broadcastjs! raise on JS error
* Drab.get_socket
* technical socket? for broadcasts from drab server

## 0.4.1
Changes:
* render partials in commanders (accutally it can already be done, just add a helper)
* before_handler, only: should take a list or atom (currently list only)
* dependencies for modules (for ex. Modal depends on Query)
* execute(:method, params) does not work when the method have more than 1 parameter
* execute(method: [parameters]) should work
* access to conn? Drab.Browser.remote_ip?


## 0.5.0
Changes:
* remove Query from the default, rename it to Drab.JQuery
* new default module, not jQuery based
* changesets for update/insert in the new base module
* group JS commands to be launched in one step, if possible
* DOM tree as a Map?

## Bugs:
* Ignoring unmatched topic "drab:/drab" in DrabPoc.UserSocket

## Future
Changes:
* broadcast to all except you (really?)
* benchmarks
* extract Drab Store and Session to standalone module (loaded by default)
* disconnect after inactive time might be hard to survive when you broadcast changes (Safari)

Performance:
* render additional, user templates in a compile-time
* compress Drab templates (js)
