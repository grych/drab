(function () {
  "use strict";
  function did() {
    return "d" + window.Drab.counter++;
  }

  function generateUUID() {
    var d = new Date().getTime();
    if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
      d += performance.now();
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = (d + Math.random() * 16) % 16 | 0;
      d = Math.floor(d / 16);
      return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
  }

  function client_id() {
    var id = localStorage.getItem("client_id");
    if (id) {
      return id;
    } else {
      id = generateUUID();
      localStorage.setItem("client_id", id);
      return id
    }
  }

  function closest(el, fn) {
    return el && (fn(el) ? el : closest(el.parentNode, fn));
  }

  window.Drab = {
    create: function (drab_return_token, drab_session_token, broadcast_topic) {
      this.Socket = <%= Drab.Config.get(endpoint, :js_socket_constructor) %>;
      this.drab_session_token = drab_session_token;
      this.self = this;
      this.counter = 0;
      this.myid = client_id();
      this.onload_launched = false;
      this.already_connected = false;
      this.drab_topic = broadcast_topic;
      this.client_lib_version = <%= client_lib_version %>;
      this.connect = function (additional_token) {
        var drab = this;

        for (var i = 0; i < drab.load.length; i++) {
          var fx = drab.load[i];
          fx(drab);
        }

        var params = Object.assign({ __drab_return: drab_return_token }, additional_token);
        params = Object.assign(params, {
          __client_lib_version: Drab.client_lib_version,
          __client_id: Drab.myid
        });
        drab.socket = new this.Socket("<%= Drab.Config.get(endpoint, :socket) %>", {
          params: params
        });
        // this.socket.onError(function(ev) {console.log("SOCKET ERROR", ev);});
        // this.socket.onClose(function(ev) {console.log("SOCKET CLOSE", ev);});

        drab.socket.connect();
        this.channel = drab.socket.channel(this.drab_topic, {});

        this.channel.join().receive("error", function (resp) {
          console.log("Unable to join the Drab Channel", resp);
        }).receive("ok", function (resp) {
          // launch on_connect
          for (var c = 0; c < drab.connected.length; c++) {
            var fxc = drab.connected[c];
            fxc(resp, drab);
          }
          drab.already_connected = true;
          drab.already_disconnected = false;
          // event is sent after Drab finish processing the event
          drab.channel.on("event", function (message) {
            if (message.finished && drab.event_reply_table[message.finished]) {
              drab.event_reply_table[message.finished]();
              delete drab.event_reply_table[message.finished];
            }
          });
        });

        drab.socket.onClose(function (event) {
          if (!drab.already_disconnected) {
            drab.already_disconnected = true;
            for (var di = 0; di < drab.disconnected.length; di++) {
              var fxd = drab.disconnected[di];
              fxd(drab);
            }
          }
        });

        this.disconnect = function () { drab.socket.conn.close(); }
      }
    },
    //
    //   event_handler -  string - function name in Phoenix Commander
    //   payload: object - will be passed as the second argument to the Event Handler
    //   execute_after - callback to function executes after event finish
    exec_elixir: function (event_handler, payload, execute_after) {
      var reply_to = did();
      if (!(payload !== null && typeof payload === 'object' && Array.isArray(payload) === false))
        payload = {payload: payload};
      var p = {};
      for (var i = 0; i < Drab.additional_payloads.length; i++) {
        var fx = Drab.additional_payloads[i];
        var event = event;
        if (typeof (event) == "undefined") {
          event = new Event("click");
        }
        p = Object.assign(p, fx(null, event));
      }
      payload = Object.assign(p, payload);
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
    error: function (message) {
      console.log("[drab] " + message);
      if (this.channel) {
        Drab.exec_elixir("Drab.Logger.error", {message: message});
      }
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
      <%= Drab.Template.render_template(endpoint, "drab.store.#{Drab.Config.get(endpoint, :drab_store_storage)}.set.js", []) %>
    },
    get_drab_store_token: function() {
      <%= Drab.Template.render_template(endpoint, "drab.store.#{Drab.Config.get(endpoint, :drab_store_storage)}.get.js", []) %>
    },
    get_drab_session_token: function () {
      return this.drab_session_token;
    }
  };

  <%=
    Enum.map(templates, fn template ->
      Drab.Template.render_template(endpoint, template, [endpoint: endpoint])
    end)
  %>

  Drab.create('<%= controller_and_action %>', '<%= drab_session_token %>', '<%= broadcast_topic %>');
  <%= if connect do %>
    Drab.connect();
  <% end %>
})();

