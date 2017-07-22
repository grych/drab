Drab.on_connect(function (resp, drab) {
  drab.channel.on("register_waiters", function (message) {
    message.waiters.forEach(function (waiter) {
      var ws = document.querySelectorAll(waiter.selector);
      ws.forEach(function (w) {
        w.setAttribute("drab_waiter_token", waiter.drab_waiter_token);
        w["on" + waiter.event_name] = function (event) {
          drab.channel.push("waiter", {
            drab_waiter_token: waiter.drab_waiter_token,
            sender: payload(w, event)
          });
        };
      });
    });
  });
  drab.channel.on("unregister_waiters", function (message) {
    // $(message.selector).off(message.event_name)
    var ws = document.querySelectorAll(message.selector);
    ws.forEach(function (w) {
      w["on" + waiter.event_name] = null;
    });
  });
});

