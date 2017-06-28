Change phoenix version:
* remove node_modules
* npm install && node_modules/brunch/bin/brunch build

Phoenix.Channel.Server.broadcast! DrabTestApp.PubSub, "__drab:same_url:/tests/live", "execjs", %{js: "console.log('foo')"}
--> raises on callback (sender?)
create new event on JS: "broadcastjs"?
run 1 Drab server, under supervisor, for broadcasting?

