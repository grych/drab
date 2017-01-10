(function(){
  function uuid() {
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0
        d = Math.floor(d/16)
        return (c=='x' ? r : (r&0x3|0x8)).toString(16)
    })
    return uuid
  }
   

  var Drab = {
    EVENTS: ["click", "change", "keyup", "keydown"],
    EVENTS_TO_DISABLE: <%= Drab.config.events_to_disable |> Drab.Query.encode_js %>,
    MODAL: "#_drab_modal",
    MODAL_FORM: "#_drab_modal form",
    MODAL_BUTTON_OK: "#_drab_modal_button_ok",
    MODAL_BUTTON_CANCEL: "#_drab_modal_button_cancel",

    run: function(drab_return) {
      this.Socket = require("phoenix").Socket
      // window.uuid = require("node-uuid")
      // window.$ = require("jquery")
      // window.jQuery = $

      this.drab_return = drab_return
      this.self = this
      // this.myid = uuid.v1()
      this.myid = uuid()
      this.onload_launched = false
      this.already_connected = false
      this.path = location.pathname

      // disable all the Drab-related objects
      // they will be re-enable on connection
      this.disable_drab_objects(true)

      let socket = new this.Socket("<%= Drab.config.socket %>", {params: {token: window.userToken}})
      socket.connect()
      this.channel = socket.channel(
        `drab:${this.path}`, 
        {
          path: this.path, 
          drab_return: this.drab_return
        })
      this.channel.join()
        .receive("error", resp => { console.log("Unable to join DRAB channel", resp) })
        .receive("ok", resp => this.connected(resp, this))
      // socket.onError(function(ev) {console.log("SOCKET ERROR", ev);});
      // socket.onClose(function(ev) {console.log("SOCKET CLOSE", ev);});
      socket.onClose((event) => {
        // on disconnect
        this.disable_drab_objects(true)
      })
    },

    disable_drab_objects: function(disable) {
      <%= if Drab.config.disable_controls_when_disconnected do %>
        for (let ev of this.EVENTS) {
          $(`[drab-${ev}]`).prop('disabled', disable)
        }
      <% end %>
    },

    connected: function(resp, him) {
      // prevent to re-assign messages
      if (!this.already_connected) {
        him.channel.on("onload", (message) => {
        })

        // exec is synchronous, returns the result
        him.channel.on("execjs", (message) => {
          let query_output = [
            message.sender,
            eval(message.js)
          ]
          him.channel.push("execjs", {ok: query_output})
        })

        // broadcast does not return a meesage
        him.channel.on("broadcastjs", (message) => {
          eval(message.js)
        })

        him.channel.on("modal", (message) => {
          $(this.MODAL_FORM).on("submit", (event) => {
            modal_button_clicked(message, "ok")
            return false // prevent submit
          })
          $(this.MODAL_BUTTON_OK).on("click", (event) => {
            $(this.MODAL_BUTTON_OK).data("clicked", true)
            modal_button_clicked(message, "ok")
          })
          $(this.MODAL).on("hidden.bs.modal", (event) => {
            if (!$(this.MODAL_BUTTON_OK).data("clicked")) {
              // if it is not an OK button (prevent double send)
              modal_button_clicked(message, "cancel")
            }
          })
          // set focus on form
          $(this.MODAL).on("shown.bs.modal", (event) => {
            $(this.MODAL_FORM + " :input").first().focus()
          })

          $(this.MODAL).modal()
        })

        this.already_connected = true
      }

      function modal_button_clicked(message, button_clicked) {
        let vals = {}
        $("#_drab_modal form :input").map(function() {
          let key = $(this).attr("name") || $(this).attr("id")
          vals[key] = $(this).val()
        })
        let query_output = [
          message.sender,
          {
            button_clicked: button_clicked, 
            params: vals
          }
        ]      
        him.channel.push("modal", {ok: query_output})        
        $('#_drab_modal').modal('hide')
      }

      // Drab Events
      function payload(who, event) {
        setid(who)
        return {
          // by default, we pass back some sender attributes
          id:   who.attr("id"),
          text: who.text(),
          html: who.html(),
          val:  who.val(),
          data: who.data(),
          drab_id: who.attr("drab-id"),
          event_handler_function: who.attr(`drab-${event}`)
        }
      }

      function setid(whom) {
        whom.attr("drab-id", uuid())
      }

      // TODO: after rejoin the even handler is doubled or tripled
      //       hacked with off(), bit I don't like it as a solution 
      for (let ev of this.EVENTS) {
        events_to_disable = this.EVENTS_TO_DISABLE
        $(`[drab-${ev}]`).off(ev).on(ev, function(event) {
          // disable current control - will be re-enabled after finish
          <%= if Drab.config.disable_controls_while_processing do %>
            if ($.inArray(ev, events_to_disable) >= 0) {
              $(this).prop('disabled', true)
            }
          <% end %>
          him.channel.push("event", {event: ev, payload: payload($(this), ev)})
        })
      }

      // re-enable drab controls
      this.disable_drab_objects(false)
      // initialize onload on server side, just once
      if (!this.onload_launched) {
        this.onload_launched = true
        him.channel.push("onload", null)
      }
    }
  }

  Drab.run('<%= controller_and_action %>')
})();
