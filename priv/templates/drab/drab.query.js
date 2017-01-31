const EVENTS = ["click", "change", "keyup", "keydown"]
const EVENTS_TO_DISABLE = <%= Drab.config.events_to_disable_while_processing |> Drab.Core.encode_js %>

// disable all drab object when disconnected from the server
Drab.disable_drab_objects = function(disable) {
  <%= if Drab.config.disable_controls_when_disconnected do %>
    $(`[drab-event]`).prop('disabled', disable)
  <% end %>
}

Drab.on_load(function(drab) {
  drab.disable_drab_objects(true)
})

Drab.on_disconnect(function(drab) {
  drab.disable_drab_objects(true)
})

Drab.on_connect(function(resp, drab) {
  function payload(who) {
    setid(who)
    return {
      // by default, we pass back some sender attributes
      id:     who.attr("id"),
      name:   who.attr("name"),
      class:  who.attr("class"),
      text:   who.text(),
      html:   who.html(),
      val:    who.val(),
      data:   who.data(),
      drab_id: who.attr("drab-id")
    }
  }

  function setid(whom) {
    whom.attr("drab-id", uuid())
  }

  // set up the controls with drab handlers
  // first serve the shortcut controls by adding the longcut attrbutes
  for (var ev of EVENTS) {
    $(`[drab-${ev}]`).each(function() {
      $(this).attr("drab-event", ev) 
      $(this).attr("drab-handler", $(this).attr(`drab-${ev}`))
    })
  }

  var events_to_disable = EVENTS_TO_DISABLE
  $("[drab-event]").each(function() {
    if($(this).attr("drab-handler")) {
      var ev=$(this).attr("drab-event")
      $(this).off(ev).on(ev, function(event) {
        var t = $(this)
        // disable current control - will be re-enabled after finish
        <%= if Drab.config.disable_controls_while_processing do %>
          if ($.inArray(ev, events_to_disable) >= 0) {
            t.prop('disabled', true)
          }
        <% end %>
        // send the message back to the server
        drab.launch_event(
          ev, 
          t.attr("drab-handler"), 
          payload(t)
          <%= if Drab.config.disable_controls_while_processing do %>
            ,
            function() {
              t.prop('disabled', false)
              // console.log("GOTREPLY!", t)
            }
          <% end %>
          )
        // drab.channel.push("event", {event: ev, payload: payload($(this))})
      })
    } else {
      console.log("Drab Error: drab-event definded without drab-handler", $(this))
    }
  })

  // re-enable drab controls
  drab.disable_drab_objects(false)
})
