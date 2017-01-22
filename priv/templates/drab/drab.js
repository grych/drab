(function(){
  function uuid() {
    // borrowed from http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = (d + Math.random()*16)%16 | 0
      d = Math.floor(d/16)
      return (c=='x' ? r : (r&0x3|0x8)).toString(16)
    })
    return uuid
  }
  
  window.Drab = {
    run: function(drab_return) {
      this.Socket = require("phoenix").Socket

      this.drab_return = drab_return
      this.self = this
      this.myid = uuid()
      this.onload_launched = false
      this.already_connected = false
      this.path = location.pathname

      // launch all on_load functions
      for(let f of this.load) {
        f(this)
      }

      let socket = new this.Socket("<%= Drab.config.socket %>", {params: {token: window.userToken}})
      socket.connect()
      this.channel = socket.channel(
        `drab:${this.path}`, 
        {
          path: this.path, 
          drab_return: this.drab_return
        })
      this.channel.join()
        .receive("error", resp => { 
          // TODO: communicate it to user 
          console.log("Unable to join the Drab Channel", resp) 
        })
        .receive("ok", resp => {
          // launch on_connect
          for(let f of this.connected) {
            f(resp, this)
          }
          this.already_connected = true
          // event is sent after Drab finish processing the event
          this.channel.on("event", (message) => {
            // console.log("EVENT: ", message)
            if(this.event_reply_table[message.finished]) {
              this.event_reply_table[message.finished]()
              delete this.event_reply_table[message.finished]
            }
          })
        })
      // socket.onError(function(ev) {console.log("SOCKET ERROR", ev);});
      // socket.onClose(function(ev) {console.log("SOCKET CLOSE", ev);});
      socket.onClose((event) => {
        // on_disconnect
        for(let f of this.disconnected) {
          f(this)
        }
      })
    },
    // 
    //   string - event name
    //   event_handler -  string - function name in Phoenix Commander
    //   payload: object - will be passed as the second argument to the Event Handler
    //   execute_after - callback to function executes after event finish
    launch_event: function(event_name, event_handler, payload, execute_after) {
      let reply_to = uuid()
      if(execute_after) {
        Drab.event_reply_table[reply_to] = execute_after
      }
      let message = {event: event_name, event_handler_function: event_handler, payload: payload, reply_to: reply_to}
      this.channel.push("event", message)
    },
    connected: [],
    disconnected: [],
    load: [],
    event_reply_table: {},
    on_connect: function(f) {
      this.connected.push(f)
    },
    on_disconnect: function(f) {
      this.disconnected.push(f)
    },
    on_load: function(f) {
      this.load.push(f)
    }
  }

  <%= 
    Enum.map(templates, fn template -> 
      Drab.Template.render_template(template, [])
    end)
  %>

  Drab.run('<%= controller_and_action %>')
})();
