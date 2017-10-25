const EVENTS = ["click", "change", "keyup", "keydown"];
const EVENTS_TO_DISABLE = <%= Drab.Config.get(:events_to_disable_while_processing) |> Drab.Core.encode_js %>;

Drab.disable_drab_objects = function (disable) {
  <%= if Drab.Config.get(:disable_controls_when_disconnected) do %>
    var found =  document.querySelectorAll("[drab-event]");
    for (var i = 0; i < found.length; i++) {
      var element = found[i];
      element['disabled'] = disable;
    };
  <% end %>
};

//http://davidwalsh.name/javascript-debounce-function
function debounce(func, wait, immediate) {
  var timeout;
  return function () {
    var context = this,
        args = arguments;
    var later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

function payload(sender, event) {
  var p;
  if (sender) {
    p = default_payload(sender, event);
  } else {
    p = {};
  }

  for (var i = 0; i < Drab.additional_payloads.length; i++) {
    var fx = Drab.additional_payloads[i];
    p = Object.assign(p, fx(sender, event));
  }

  return p;
}

// default payload contains sender information and some info about event
function default_payload(sender, event) {
  var params = {};
  var form = closest(sender, function (el) {
    return el.nodeName == "FORM";
  });
  if (form) {
    var inputs = form.querySelectorAll("input, textarea, select");
    for (var i = 0; i < inputs.length; i++) {
      var input = inputs[i];
      var key = input.name || input.id || false;
      if (key) {
        if (input.type == "radio" || input.type == 'checkbox') {
          if (input.checked) {
            params[key] = input.value;
          }
        } else {
          params[key] = input.value;
        }
      }
    };
  }
  return {
    // by default, we pass back some sender properties
    id: sender.id,
    name: sender.name,
    class: sender.className,
    classes: sender.classList,
    text: sender.innerText,
    html: sender.innerHTML,
    value: sender.value,
    dataset: sender.dataset,
    drab_id: sender.getAttribute("drab-id"),
    event: {
      altKey: event.altKey,
      data: event.data,
      key: event.key,
      keyCode: event.keyCode,
      metaKey: event.metaKey,
      shiftKey: event.shiftKey,
      ctrlKey: event.ctlrKey,
      type: event.type,
      which: event.which,
      clientX: event.clientX,
      clientY: event.clientY,
      offsetX: event.offsetX,
      offsetY: event.offsetY,
      pageX: event.pageX,
      pageY: event.pageY,
      screenX: event.screenX,
      screenY: event.screenY
    },
    form: params
  };
}

function do_setid(whom) {
  if (!whom.getAttribute("drab-id")) {
    whom.setAttribute("drab-id", uuid());
  }
}

Drab.setid = function (whom) {
  if (Array.isArray(whom)) {
    for (var i = 0; i < whom.length; i++) {
      var x = whom[i]
      do_setid(x);
    };
  } else {
    do_setid(whom);
  }
  return whom.getAttribute("drab-id");
};

function update_event_handler(node, event, func) {
  // TODO: learn more about event listeners
  // node.removeEventListener(event, func)
  // node.addEventListener(event, func)
  node["on" + event] = func;
}

Drab.enable_drab_on = function(selector) {
  for (var i = 0; i < Drab.change.length; i++) {
    var fx = Drab.change[i];
    fx(selector);
  }
  Drab.set_event_handlers(selector);
}

// re-read event handlers
Drab.set_event_handlers = function (obj) {
  var drab_objects = [];
  var drab_objects_shortcut = [];

  // first serve the shortcut controls by adding the longcut attrbutes
  for (var ei = 0; ei < EVENTS.length; ei++) {
    var ev = EVENTS[ei];
    if (obj) {
      var o = document.querySelector(obj);
      if (o) {
        drab_objects_shortcut = o.parentNode.querySelectorAll("[drab-" + ev + "]");
      }
    } else {
      drab_objects_shortcut = document.querySelectorAll("[drab-" + ev + "]");
    }
    for (var i = 0; i < drab_objects_shortcut.length; i++) {
      var node = drab_objects_shortcut[i];
      node.setAttribute("drab-event", ev);
      node.setAttribute("drab-handler", node.getAttribute("drab-" + ev));
    };
  }

  if (obj) {
    var o = document.querySelector(obj);
    if (o) {
      drab_objects = o.parentNode.querySelectorAll("[drab-event]");
    }
  } else {
    drab_objects = document.querySelectorAll("[drab-event]");
  }

  var events_to_disable = EVENTS_TO_DISABLE;

  for (var i = 0; i < drab_objects.length; i++) {
    var node = drab_objects[i];
    if (node.getAttribute("drab-handler")) {

      var event_handler_function = function (event) {
        // disable current control - will be re-enabled after finish
        var n = this;
        <%= if Drab.Config.get(:disable_controls_while_processing) do %>
          if (events_to_disable.indexOf(event.type) >= 0) {
            n['disabled'] = true;
          }
        <% end %>
        Drab.setid(n);
        // send the message back to the server
        Drab.exec_elixir(
          n.getAttribute("drab-handler"),
          payload(n, event)
          <%= if Drab.Config.get(:disable_controls_while_processing) do %>
            , function() {
                n['disabled'] = false
              }
          <% end %>
        );
        return false; // prevent default
      };

      var event_name = node.getAttribute("drab-event");

      // options. Wraps around event_handler_function, eg. debounce(event_handler_function, 500)
      var options = node.getAttribute("drab-options");
      var matched = /(\w+)\s*\((.*)\)/.exec(options);
      if (matched) {
        var fname = matched[1];
        var fargs = matched[2].replace(/^\s+|\s+$/g, ''); // strip whitespace
        var f = fname + "(event_handler_function" + (fargs == "" ? "" : ", " + fargs) + ")";
        update_event_handler(node, event_name, eval(f));
      } else {
        update_event_handler(node, event_name, event_handler_function);
      }
    } else {
      console.log("Drab Error: drab-event definded without drab-handler", this);
    }
  };
};

Drab.on_load(function (drab) {
  drab.disable_drab_objects(true);
});

Drab.on_disconnect(function (drab) {
  drab.disable_drab_objects(true);
});

Drab.on_connect(function (resp, drab) {
  drab.set_event_handlers();

  // re-enable drab controls
  drab.disable_drab_objects(false);
});

