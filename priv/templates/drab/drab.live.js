Drab.on_load(function (resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  if (typeof window.__drab == 'undefined') {
    window.__drab = { assigns: {} };
  };
  var d = window.__drab;
  set_properties(document);
});

Drab.on_change(function(node) {
  if (node) {
    // console.log("change");
    // invalidate_assigns_cache();
    run_drab_scripts_on(node);
    set_properties(node);
  }
});

// function invalidate_assigns_cache() {
//   Drab.exec_elixir("Drab.Live.Commander.invalidate_assigns_cache", {});
// }

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
      var nodes = ampere_nodes(ampere);
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

function ampere_nodes(ampere) {
  return document.querySelectorAll(selector(ampere));
}

function where(shared_commander) {
  if (shared_commander === "document") {
    return document;
  } else {
    return document.querySelector("[drab-id='" + shared_commander + "']");
  }
}

Drab.update_attribute = function (ampere, attribute, shared_commander, new_value) {
  var nodes = ampere_nodes(ampere);
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    // a corner case for <input value="">
    if ((node.tagName == "INPUT" || node.tagName == "TEXAREA") && attribute.toLowerCase() == "value") {
      node.value = new_value;
    }
    node.setAttribute(attribute, new_value);
  }
}

Drab.update_property = function (ampere, property, shared_commander, new_value) {
  var nodes = ampere_nodes(ampere);
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    set_property(node, ampere, property, new_value);
  }
}

Drab.update_tag = function(tag, ampere, shared_commander, new_value) {
  switch(tag) {
    // TODO: script should also work under the shared commander
    case "script":
      eval(new_value);
      break;
    default:
      var s = selector(ampere);
      var nodes = where(shared_commander).querySelectorAll(s);
      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        node.innerHTML = new_value;
      }
      Drab.enable_drab_on(s);
  }
};

