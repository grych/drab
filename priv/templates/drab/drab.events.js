const EVENT_SHORTCUTS = <%= Drab.Config.get(:events_shorthands) |> Drab.Core.encode_js %>;
const EVENTS_TO_DISABLE = <%= Drab.Config.get(:events_to_disable_while_processing) |> Drab.Core.encode_js %>;

Drab.save_disabled_state = function() {
  var drabs = document.querySelectorAll("[drab]");
  for (var i = 0; i < drabs.length; i++) {
    var element = drabs[i];
    element.drab_disable_state = element.disabled;
  };
};

Drab.disable_drab_objects = function (disable) {
  <%= if Drab.Config.get(:disable_controls_when_disconnected) do %>
    var found =  document.querySelectorAll("[drab]");
    for (var i = 0; i < found.length; i++) {
      var element = found[i];
      element.disabled = disable || element.drab_disable_state;
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

function payload(sender, event, argument) {
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

  p.__additional_argument = argument;

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
        } else if (input.type == "select-multiple") {
          var values=[];
          for (var j = 0; j < input.options.length; j++) {
            var option = input.options[j];
            if (option.selected) values.push(option.value);
          }
          params[key] = values;
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
    whom.setAttribute("drab-id", did());
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
  if (!node.drab_event_handler) {
    node.drab_event_handler = {};
  }
  if (node.drab_event_handler[event]) {
    node.removeEventListener(event, node.drab_event_handler[event]);
  }
  node.addEventListener(event, func);
  node.drab_event_handler[event] = func;
}

Drab.enable_drab_on = function(selector_or_node) {
  var node;
  if (typeof selector_or_node == "string" || selector_or_node instanceof String)
    node = document.querySelector(selector_or_node);
  else
    node = selector_or_node;
  for (var i = 0; i < Drab.change.length; i++) {
    var fx = Drab.change[i];
    fx(node);
  }
  Drab.set_event_handlers(node);
}

function add_drab_attribute(node, event, handler, options) {
  if ((!event) || (!handler)) {
    Drab.error("Event and handler name must be set for: " + node);
  } else {
    var events_and_handlers = node.getAttribute("drab") || "";
    var new_event_handler = event + (options ? "#" + options : "") + ":" + handler;
    var re = new RegExp(event + "[:#]\\S");
    if (re.exec(events_and_handlers) === null) {
      var attr = events_and_handlers + " " + new_event_handler;
      node.setAttribute("drab", attr.trim());
    }
  }
}

function add_drab_commander(node, commander) {
  var events_and_handlers = split_drab_attribute(node.getAttribute("drab"));
  var attr = "";
  for (var i = 0; i < events_and_handlers.length; i++) {
    var drab_attr = parse_drab_attr(events_and_handlers[i]);
    if (drab_attr) {
      if (!drab_attr.in_shared_commander) {
        drab_attr.handler_name = commander + "." + drab_attr.handler_name;
      }
    }
    attr = attr + drab_attr.event_name + ":" + drab_attr.handler_name + " ";
  }
  node.setAttribute("drab", attr.trim());
}

function add_drab_argument(node, argument) {
  var events_and_handlers = split_drab_attribute(node.getAttribute("drab"));
  var attr;
  for (var i = 0; i < events_and_handlers.length; i++) {
    // var drab_attr = parse_drab_attr(events_and_handlers[i]);
    var drab_attr = events_and_handlers[i];
    var m = /(.+)\((.*)\)$/.exec(drab_attr);
    if (m) {
      if (m[2] == "") {
        attr = m[1] + "(" + argument + ")"
      } else {
        attr = drab_attr;
      }
    } else {
      attr = drab_attr + "(" + argument + ")";
    }
  }
  node.setAttribute("drab", attr);
}

function find_drab_commander_attr(where) {
  do_find_drab_attr(where, "drab-commander", add_drab_commander);
}

function find_drab_argument_attr(where) {
  do_find_drab_attr(where, "drab-argument", add_drab_argument);
}

function do_find_drab_attr(where, attr_name, add_drab_function) {
  var attribute_nodes = where.querySelectorAll("[" + attr_name + "]");
  for (var i = 0; i < attribute_nodes.length; i++) {
    var attribute_node = attribute_nodes[i];
    var attribute_node_id;
    if (attr_name == "drab-commander") {
      attribute_node_id= Drab.setid(attribute_node);
    }
    var attribute = attribute_node.getAttribute(attr_name);
    var nodes = attribute_node.querySelectorAll("[drab]");
    for (var j = 0; j < nodes.length; j++) {
      var node = nodes[j];
      add_drab_function(node, attribute);
      if (attr_name == "drab-commander") {
        node.setAttribute("drab-commander-id", attribute_node_id);
      }
    }
  }
}

function split_to_first(str, pattern) {
  var i = str.indexOf(pattern);
  return [str.substring(0, i), str.substring(i+1)]
}

function parse_drab_attr(attr) {
  var l = split_to_first(attr, ":");
  var event_with_options = l[0].split("#");
  var event_name = event_with_options[0];
  var options = event_with_options[1];
  var handler_name = l[1];
  var up_to_parenthesis = handler_name && handler_name.match(/^[^(]+/)[0];
  var in_shared_commander = up_to_parenthesis && (up_to_parenthesis.indexOf(".") !== -1)
  if (event_name && handler_name) {
    return {
      handler_name: handler_name,
      event_name: event_name,
      options: options,
      in_shared_commander: in_shared_commander
    };
  } else {
    Drab.error("Drab attribute value '" + attr + "' is incorrect.");
    return false;
  }
}

function count(string, regexp) {
  return (string.match(new RegExp(regexp, 'g')) || []).length;
}

function split_drab_attribute(attr) {
  var list = attr.match(/\S+/g);
  var ret = [];
  for (var i = 0; i < list.length; i++) {
    var str = list[i];
    var opened = count(str, "\\(");
    var closed = count(str, "\\)");
    if (opened != closed) {
      do {
        i++;
        if (i == list.length) break;
        var s = list[i];
        opened = opened + count(s, "\\(");
        closed = closed + count(s, "\\)");
        str = str + " " + s;
      } while (opened !== closed);
    }
    ret.push(str);
  }
  return ret;
}

function set_drab_attribute(where) {
  // first serve the shortcut controls by adding the internal attribute
  for (var ei = 0; ei < EVENT_SHORTCUTS.length; ei++) {
    var ev = EVENT_SHORTCUTS[ei];

    var drab_objects_shortcutted = where.querySelectorAll("[drab-" + ev + "]");
    for (var i = 0; i < drab_objects_shortcutted.length; i++) {
      var node = drab_objects_shortcutted[i];
      add_drab_attribute(node, ev, node.getAttribute("drab-" + ev), node.getAttribute("drab-options"));
    };
  }

  // long way, to be depreciated
  // drab-event= drab-handler= drab-options=
  var drab_objects_long = where.querySelectorAll("[drab-event]");
  for (var i = 0; i < drab_objects_long.length; i++) {
    var node = drab_objects_long[i];
    add_drab_attribute(
      node,
      node.getAttribute("drab-event"),
      node.getAttribute("drab-handler"),
      node.getAttribute("drab-options")
    )
  }

  find_drab_argument_attr(where);
  find_drab_commander_attr(where);
}

// re-read event handlers
Drab.set_event_handlers = function (node) {
  var drab_objects = [];
  var where = node ? node.parentNode : document;

  set_drab_attribute(where);

  var events_to_disable = EVENTS_TO_DISABLE;
  drab_objects = where.querySelectorAll("[drab]")

  for (var i = 0; i < drab_objects.length; i++) {
    var node = drab_objects[i];
    Drab.setid(node);
    var events_and_handlers = split_drab_attribute(node.getAttribute("drab"));
    for (var j = 0; j < events_and_handlers.length; j++) {
      let drab_attr = parse_drab_attr(events_and_handlers[j]);
      let handler_name = drab_attr.handler_name;

      if (drab_attr) {
        var event_handler_function = function (event) {
          // disable current control - will be re-enabled after finish
          var n = this;
          <%= if Drab.Config.get(:disable_controls_while_processing) do %>
            if (events_to_disable.indexOf(event.type) >= 0) {
              n['disabled'] = true;
            }
          <% end %>
          var m, argument, parsed_handler_name;
          if ((m = /([\w\.]+)\((.*)\)$/.exec(handler_name)) !== null) {
            parsed_handler_name = m[1];
            var t = m[2].trim() == "" ? null : m[2];
            argument = eval("var tmp=" + t + "; tmp");
          }
          // send the message back to the server
          Drab.exec_elixir(
            parsed_handler_name || handler_name,
            payload(n, event, argument)
            <%= if Drab.Config.get(:disable_controls_while_processing) do %>
              , function() {
                  n['disabled'] = false
                }
            <% end %>
          );
          event.preventDefault();
          return false; // prevent default
        };

        // options. Wraps around event_handler_function, eg. debounce(event_handler_function, 500)
        var matched = /(\w+)\s*\((.*)\)/.exec(drab_attr.options);
        if (matched) {
          var fname = matched[1];
          var fargs = matched[2].trim();
          var f = fname + "(event_handler_function" + (fargs == "" ? "" : ", " + fargs) + ")";
          update_event_handler(node, drab_attr.event_name, eval(f));
        } else {
          update_event_handler(node, drab_attr.event_name, event_handler_function);
        }
      }
    }
  };
};

Drab.on_load(function (drab) {
  set_drab_attribute(document);
  drab.save_disabled_state();
  drab.disable_drab_objects(true);
});

Drab.on_disconnect(function (drab) {
  drab.save_disabled_state();
  drab.disable_drab_objects(true);
});

Drab.on_connect(function (resp, drab) {
  drab.set_event_handlers();
  // re-enable drab controls
  drab.disable_drab_objects(false);
});

