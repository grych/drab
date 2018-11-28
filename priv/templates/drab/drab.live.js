Drab.on_load(function (resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  if (typeof window.__drab == 'undefined') {
    window.__drab = { assigns: {} };
  };
  set_properties(document);
  if (!window.__drab.csrf) {
    window.__drab.csrf = find_csrf();
  }
});

Drab.on_change(function(node) {
  if (node) {
    run_drab_scripts_on(node);
    set_properties(node);
  }
});

Drab.add_payload(function(sender) {
  return {drab_index: __drab.index, csrf_token: __drab.csrf};
});

Drab.add_payload(function(sender) {
  if (sender) {
    var shared_commander_id = sender.getAttribute("drab-commander-id");
    if (shared_commander_id) {
      var amperes = [];
      var shared_commander = document.querySelector("[drab-id='" + shared_commander_id + "']");
      var ampered_nodes = shared_commander.querySelectorAll("[drab-ampere]");
      for (var i = 0; i < ampered_nodes.length; i++) {
        amperes.push(ampered_nodes[i].getAttribute("drab-ampere"));
      }
      return {
        drab_commander_id: shared_commander_id,
        drab_commander_amperes: amperes
      };
    }
  } else {
    return {};
  }
});

function find_csrf() {
  var node;
  if (node = document.querySelector("input[name='_csrf_token']")) {
    return node.value;
  }
  if (node = document.querySelector("button[data-csrf]")) {
    return node.dataset.csrf;
  }
  if (node = document.querySelector("a[data-csrf]")) {
    return node.dataset.csrf;
  }
  return null;
}

function run_drab_scripts_on(node) {
  var scripts = node.querySelectorAll("script[drab-script]");
  for (var i = 0; i < scripts.length; i++) {
    var script = scripts[i];
    eval(script.innerText);
  }
}

function set_properties(where) {
  var d = window.__drab;
  for (var ampere in d.properties) {
    var properties = d.properties[ampere];
    for (var property in properties) {
      var nodes = ampere_nodes(ampere, where);
      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        set_property(node, ampere, property, properties[property]);
      }
    }
  }

}

function set_property(node, ampere, property, new_value) {
  var path = property.split(".");
  var full = node;
  var prev, last;
  for (var i = 0; i < path.length; i++) {
    var part = path[i];
    prev = full;
    full = full[part];
    last = part;
  }
  prev[last] = new_value;
  window.__drab.properties[ampere][property] = new_value;
}

function selector(ampere) {
  return "[drab-ampere='" + ampere + "']";
}

function ampere_nodes(ampere, where) {
  var node = where ? where : document;
  return node.querySelectorAll(selector(ampere));
}

Drab.update_attribute = function (ampere, attribute, new_value) {
  var nodes = ampere_nodes(ampere);
  var n = 0;
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    // a corner case for <input value="">
    if ((node.tagName == "INPUT" || node.tagName == "TEXAREA") && attribute.toLowerCase() == "value") {
      node.value = new_value;
      n++;
    }
    node.setAttribute(attribute, new_value);
  }
  return n;
}

Drab.update_property = function (ampere, property, new_value) {
  var nodes = ampere_nodes(ampere);
  var n = 0;
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    set_property(node, ampere, property, new_value);
    n++;
  }
  return n;
}

function set_inner_html(node, tag, new_value) {
  switch (tag) {
    case "textarea":
      node.value = new_value;
    default:
      node.innerHTML = new_value;
  }
}

Drab.update_tag = function(tag, ampere, new_value) {
  var n = 0;
  switch(tag) {
    case "script":
      eval(new_value);
      break;
    default:
      var s = selector(ampere);
      var nodes = document.querySelectorAll(s);

      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        set_inner_html(node, tag, new_value);
        n++;
      }
      Drab.enable_drab_on(s);
  }
  return n;
};

