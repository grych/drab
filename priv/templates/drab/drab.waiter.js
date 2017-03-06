Drab.on_connect(function(resp, drab) {
  drab.channel.on("register_waiters", function(message) {
    // Drab.Query.update(attr: "drab_waiter_token", set: waiter_token, on: selector)

    message.waiters.forEach(function(waiter) {
    $(waiter.selector).attr("drab_waiter_token", waiter.drab_waiter_token)
      $(waiter.selector).off(waiter.event_name).on(waiter.event_name, function(event) {
        var t = $(this)
        drab.channel.push("waiter", {
          drab_waiter_token: waiter.drab_waiter_token, 
          sender: payload(t, event)
        })
      })
    })
  })
  drab.channel.on("unregister_waiters", function(message) {
    $(message.selector).off(message.event_name)
  })
})
