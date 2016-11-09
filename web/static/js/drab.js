import {Socket} from "phoenix"
import uuid from "node-uuid"
import $ from "jquery"

export var Drab = {
  EVENTS: ["click", "change", "keyup", "keydown"],
  MODAL: "#_drab_modal",
  MODAL_FORM: "#_drab_modal form",
  MODAL_BUTTON_OK: "#_drab_modal_button_ok",
  MODAL_BUTTON_CANCEL: "#_drab_modal_button_cancel",

  run: function(drab_return) {
    this.drab_return = drab_return
    this.self = this
    this.myid = uuid.v1()
    this.onload_launched = false
    this.already_connected = false
    this.path = location.pathname

    // disable all the Drab-related objects
    // they will be re-enable on connection
    this.disable_drab_objects(true)

    let socket = new Socket("/drab/socket", {params: {token: window.userToken}})
    socket.connect()
    this.channel = socket.channel(
      `drab:${this.path}`, 
      {
        path: this.path, 
        drab_return: this.drab_return
      })
    this.channel.join()
      .receive("error", resp => { console.log("Unable to join", resp) })
      .receive("ok", resp => this.connected(resp, this))
    // socket.onError(function(ev) {console.log("SOCKET ERROR", ev);});
    // socket.onClose(function(ev) {console.log("SOCKET CLOSE", ev);});
    socket.onClose((event) => {
      // on disconnect
      this.disable_drab_objects(true)
    })
  },

  disable_drab_objects: function(disable) {
    for (let ev of this.EVENTS) {
      $(`[drab-${ev}]`).prop('disabled', disable)
    }
  },

  connected: function(resp, him) {
    // prevent to re-assign messages
    if (!this.already_connected) {
      him.channel.on("onload", (message) => {
      })

      him.channel.on("execjs", (message) => {
        let query_output = [
          message.sender,
          eval(message.js)
        ]
        him.channel.push("execjs", {ok: query_output})
      })

      him.channel.on("modal", (message) => {
        // $(this.MODAL_FORM).on("submit", (event) => {
        //   modal_button_clicked(message, "ok")
        //   return false // prevent submit
        // })
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
        event_function: who.attr(`drab-${event}`)
      }
    }
    function setid(whom) {
      whom.attr("drab-id", uuid.v1())
    }
    // TODO: after rejoin the even handler is doubled or tripled
    //       hacked with off(), bit I don't like it as a solution 
    for (let ev of this.EVENTS) {
      $(`[drab-${ev}]`).off(ev).on(ev, function(event) {
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


