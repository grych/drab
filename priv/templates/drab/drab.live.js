// Drab.add_payload(function (sender, event) {
//   return {
//     __assigns: __drab.assigns,
//     __amperes: __drab.amperes,
//     __index: __drab.index
//   };
// });

Drab.on_load(function (resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  if (typeof window.__drab == 'undefined') {
    window.__drab = { assigns: {} };
  };
  var d = window.__drab;
  set_properties(document);
});

Drab.on_connect(function(resp, drab) {
  save_assigns();
})

Drab.on_change(function(selector) {
  var node = document.querySelector(selector);
  if (node) {
    // search_for_drab(node);
    run_drab_scripts_on(node);
    set_properties(node);
  }
});

function save_assigns() {
  var payload = {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes,
    __index: __drab.index
  };
  Drab.exec_elixir("Drab.Live.Commander.save_assigns", payload);
}

function run_drab_scripts_on(node) {
  var scripts = node.querySelectorAll("script[drab-script]");
  for (var i = 0; i < scripts.length; i++) {
    var script = scripts[i];
    eval(script.innerText);
  }
  save_assigns();
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

Drab.update_attribute = function(ampere, attribute, new_value) {
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

Drab.update_property = function(ampere, property, new_value) {
  var nodes = ampere_nodes(ampere);
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    set_property(node, ampere, property, new_value);
  }
}

Drab.update_tag = function(tag, ampere, new_value) {
  switch(tag) {
    case "script":
      eval(new_value);
      break;
    default:
      var s = selector(ampere);
      var nodes = document.querySelectorAll(s);
      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        node.innerHTML = new_value;
      }
      Drab.enable_drab_on(s);
  }
};

