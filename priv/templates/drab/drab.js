(function () {
  "use strict";
  function uuid() {
    // borrowed from http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (d + Math.random() * 16) % 16 | 0;
      d = Math.floor(d / 16);
      return (c == 'x' ? r : r & 0x3 | 0x8).toString(16);
    });
    return uuid;
  }

  function closest(el, fn) {
    return el && (fn(el) ? el : closest(el.parentNode, fn));
  }

  window.Drab = {
    run: function (drab_return_token, drab_session_token, broadcast_topic) {
      this.Socket = require("phoenix").Socket;

      this.drab_return_token = drab_return_token;
      this.drab_session_token = drab_session_token;
      this.self = this;
      this.myid = uuid();
      this.onload_launched = false;
      this.already_connected = false;
      this.drab_topic = broadcast_topic;

      var drab = this;

      for (var i = 0; i < drab.load.length; i++) {
        var fx = drab.load[i];
        fx(drab);
      }

      this.socket = new this.Socket("<%= Drab.Config.get(:socket) %>", { params: { __drab_return: drab_return_token } });
      this.socket.connect();
      this.channel = this.socket.channel("__drab:" + this.drab_topic, {});

      this.channel.join().receive("error", function (resp) {
        // TODO: communicate it to user
        console.log("Unable to join the Drab Channel", resp);
      }).receive("ok", function (resp) {
        // launch on_connect
        for (var c = 0; c < drab.connected.length; c++) {
          var fxc = drab.connected[c];
          fxc(resp, drab);
        }
        drab.already_connected = true;
        // event is sent after Drab finish processing the event
        drab.channel.on("event", function (message) {
          // console.log("EVENT: ", message)
          if (message.finished && drab.event_reply_table[message.finished]) {
            drab.event_reply_table[message.finished]();
            delete drab.event_reply_table[message.finished];
          }
        });
      });
      // socket.onError(function(ev) {console.log("SOCKET ERROR", ev);});
      // socket.onClose(function(ev) {console.log("SOCKET CLOSE", ev);});
      this.socket.onClose(function (event) {
        for (var di = 0; di < drab.disconnected.length; di++) {
          var fxd = drab.disconnected[di];
          fxd(drab);
        }
      });
    },
    //
    //   event_handler -  string - function name in Phoenix Commander
    //   payload: object - will be passed as the second argument to the Event Handler
    //   execute_after - callback to function executes after event finish
    exec_elixir: function (event_handler, payload, execute_after) {
      var reply_to = uuid();
      if (execute_after) {
        Drab.event_reply_table[reply_to] = execute_after;
      }
      var message = {
        event_handler_function: event_handler,
        payload: payload,
        reply_to: reply_to
      };
      this.channel.push("event", message);
    },
    run_handler: function(event_name, event_handler, payload, execute_after) {
      console.log("Drab.run_handler() is depreciated. Please use Drab.exec_elixir() instead");
      this.exec_elixir(event_handler, payload, execute_after);
    },
    connected: [],
    disconnected: [],
    load: [],
    change: [],
    additional_payloads: [],
    event_reply_table: {},
    on_connect: function (f) {
      this.connected.push(f);
    },
    on_disconnect: function (f) {
      this.disconnected.push(f);
    },
    on_load: function (f) {
      this.load.push(f);
    },
    on_change: function(f) {
      this.change.push(f);
    },
    add_payload: function (f) {
      this.additional_payloads.push(f);
    },
    set_drab_store_token: function(token) {
      <%= Drab.Template.render_template("drab.store.#{Drab.Config.get(:drab_store_storage) |> Atom.to_string}.set.js", []) %>
    },
    get_drab_store_token: function() {
      <%= Drab.Template.render_template("drab.store.#{Drab.Config.get(:drab_store_storage) |> Atom.to_string}.get.js", []) %>
    },
    get_drab_session_token: function () {
      return this.drab_session_token;
    }
  };

  <%=
    Enum.map(templates, fn template ->
      Drab.Template.render_template(template, [])
    end)
  %>

  Drab.run('<%= controller_and_action %>', '<%= drab_session_token %>', '<%= broadcast_topic %>');
})();

