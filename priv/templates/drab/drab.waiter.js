Drab.on_connect(function(resp, drab) {
  drab.channel.on("register_waiter", function(message) {
    // Drab.Query.update(attr: "drab_waiter_token", set: waiter_token, on: selector)
    $(message.selector).attr("drab_waiter_token", message.drab_waiter_token)
    $(message.selector).on(message.event_name, function(event) {
      var t = $(this)
      drab.channel.push("waiter", {
        drab_waiter_token: message.drab_waiter_token, 
        sender: payload(t, event)
      })
    })

  })
})
