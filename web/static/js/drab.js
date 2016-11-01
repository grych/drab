import {Socket} from "phoenix"
import uuid from "node-uuid"
import $ from "jquery"

export var Drab = {
  run: function(drab_return) {
    this.drab_return = drab_return
    this.self = this
    this.myid = uuid.v1()
    let socket = new Socket("/drab/socket", {params: {token: window.userToken}})
    socket.connect()
    this.channel = socket.channel(`drab:${this.myid}`, [])
    // console.log(this)
    this.channel.join()
      .receive("error", resp => { console.log("Unable to join", resp) })
      .receive("ok", resp => this.connected(resp, this))
  },

  connected: function(resp, him) {
    // console.log("Joined successfully", resp)
    him.channel.on("onload", (message) => {
      // console.log("onload message:", message)
    })
    // handler for "query" message from the server
    him.channel.on("query", (message) => {
      // console.log("he is:", him)
      // console.log("message: ", $(message))
      let r = $(message.query)
      // console.log("reply: ", r)
      let query_output = [
        message.query,
        message.sender,
        $(message.query).map(() => {
          return eval(`$(this).${message.get_function}`)
        }).toArray()
      ]
      him.channel.push("query", {ok: query_output})
    })

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
    let events = ["click", "change", "keyup", "keydown"]
    for (let ev of events) {
      // let ev = events[i]
      // console.log(ev)
      $(`[drab-${ev}]`).off(ev).on(ev, function(event) {
        him.channel.push("event", {event: ev, payload: payload($(this), ev)})
      })
    }
    // $("[drab-click]").off('click').on("click", function(event) {
    //   him.channel.push("event", {event: "click", payload: payload($(this), "click")})
    // })
    // $("[drab-change]").off('change').on("change", function(event) {
    //   him.channel.push("event", {event: "change", payload: payload($(this), "change")})
    // })
    // $("[drab-keyup]").off('keyup').on("keyup", function(event) {
    //   him.channel.push("event", {event: "keyup", payload: payload($(this), "keyup")})
    // })
    // $("[drab-keydown]").off('keydown').on("keydown", function(event) {
    //   him.channel.push("event", {event: "keydown", payload: payload($(this), "keydown")})
    // })
    // initialize onload on server side
    him.channel.push("onload", {path: location.pathname, drab_return: this.drab_return})
  }
}

// export default Drab
