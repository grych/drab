Drab.on_connect(function (resp, drab) {
  drab.channel.on("register_waiters", function (message) {
    for (var i = 0; i < message.waiters.length; i++) {
      (function(waiter) {
        var ws = document.querySelectorAll(waiter.selector);
        for (var wi = 0; wi < ws.length; wi++) {
          var w = ws[wi];
          w.setAttribute("drab_waiter_token", waiter.drab_waiter_token);
          w["on" + waiter.event_name] = function (event) {
            drab.channel.push("waiter", {
              drab_waiter_token: waiter.drab_waiter_token,
              sender: payload(this, event)
            });
          };
        }
      })(message.waiters[i]);
    }
  });
  drab.channel.on("unregister_waiters", function (message) {
    // $(message.selector).off(message.event_name)
    var ws = document.querySelectorAll(message.selector);
    for (var ui = 0; ui < ws.length; ui++) {
      var w = ws[ui];
      w["on" + waiter.event_name] = null;
    }
  });
});

