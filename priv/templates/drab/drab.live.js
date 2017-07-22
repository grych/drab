Drab.add_payload(function (sender, event) {
  return {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes,
    __index: __drab.index
  };
});

Drab.on_load(function (resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  if (typeof window.__drab == 'undefined') {
    window.__drab = { assigns: {} };
  };
  var d = window.__drab;
  d.amperes = {};
  d.properties = {};
  var found = document.querySelectorAll("[drab-partial]");
  for (var i = 0; i < found.length; i ++) {
    var partial = found[i];
    var partial_id = partial.getAttribute("drab-partial");
    d.amperes[partial_id] = [];
  };

  found = document.querySelectorAll("[drab-partial] [drab-ampere]");
  for (var i = 0; i < found.length; i++) {
    var node = found[i];
    var drab_id = node.getAttribute("drab-ampere");
    var partial = closest(node, function (el) {
      return el.hasAttribute("drab-partial");
    });
    var partial_id = partial.getAttribute("drab-partial");
    if (d.amperes[partial_id].indexOf(drab_id) < 0) {
      d.amperes[partial_id].push(drab_id);
    }
  };
  // update the properties set in <tag @property=expression>
  set_properties(document);
  // get the name of the main partial
  if (document.querySelector("[drab-partial]")) {
    d.index = document.querySelector("[drab-partial]").getAttribute("drab-partial");
  }
});

function set_properties(where) {
  var d = window.__drab;

  var found = document.querySelectorAll("[drab-ampere]");
  for (var i = 0; i < found.length; i++) {
    var node = found[i];
    // find the properties
    var drab_id = node.getAttribute("drab-ampere");
    d.properties[drab_id] = [];
    for (var j = 0; j < node.attributes.length; j++) {
      var attr_name = node.attributes[j].name;
      if (attr_name.startsWith("@")) {
        var p = {};
        p[attr_name.replace(/^@/, "")] = JSON.parse(node.attributes[j].value.replace(/^[^{]*{{{{/, "").replace(/}}}}$/, ""));
        d.properties[drab_id].push(p);
      }
    }
  };
  for (var ampere in d.properties) {
    var properties = d.properties[ampere];
    for (var j = 0; j < properties.length; j++) {
      for (key in properties[j]) {
        var amps = where.querySelectorAll("[drab-ampere='" + ampere + "']")
        for (var k = 0; k < amps.length; k++) {
          var n = amps[k];
          set_property(n, key, properties[j][key]);
        };
      }
    }
  }
}

function set_property(node, attribute_name, attribute_value) {
  var property = node.getAttribute("@" + attribute_name).replace(/{{{{.+}}}}$/, "");
  var path = property.split(".");
  var full = node;
  var prev, last;
  for (var i = 0; i < path.length; i++) {
    var part = path[i];
    prev = full;
    full = full[part];
    last = part;
  }
  prev[last] = attribute_value;
}

function selector(ampere_hash) {
  return "[drab-ampere='" + ampere_hash + "']";
}

function set_attr(where, ampere_hash, attribute_name, new_value) {
  var found = where.querySelectorAll(selector(ampere_hash));
  for (var i = 0; i < found.length; i++) {
    var node = found[i];
    node.setAttribute(attribute_name, new_value);
    // exception for "value", set the property as well
    //TODO: full list of exceptions
    if (attribute_name == "value") {
      node.value = new_value;
    }
  };
}

Drab.update_attr = function (ampere_hash, attribute_name, new_value, partial) {
  if (partial != null) {
    var found = document.querySelectorAll('[drab-partial=' + partial + ']');
    for (var i = 0; i < found.length; i++) {
      var part = found[i];
      set_attr(part, ampere_hash, attribute_name, new_value);
    };
  } else {
    set_attr(document, ampere_hash, attribute_name, new_value);
  }
};

function set_prop(where, ampere_hash, property_name, new_value) {
  var found = where.querySelectorAll(selector(ampere_hash));
  for (var i = 0; i < found.length; i++) {
    var node = found[i];
    set_property(node, property_name, new_value);
  };
}

Drab.update_prop = function (ampere_hash, property_name, new_value, partial) {
  if (partial != null) {
    var found = document.querySelectorAll('[drab-partial=' + partial + ']');
    for (var i = 0; i < found.length; i++) {
      var part = found[i];
      set_prop(part, ampere_hash, property_name, new_value);
    };
  } else {
    set_prop(document, ampere_hash, property_name, new_value);
  }
};

function set_tag_html(where, ampere_hash, html) {
  var found = where.querySelectorAll(selector(ampere_hash));
  for (var i = 0; i < found.length; i++) {
    var node = found[i];
    node.innerHTML = html;
  };
}

Drab.update_drab_span = function (ampere_hash, html, partial) {
  if (partial != null) {
    var found_partial = document.querySelectorAll('[drab-partial=' + partial + ']');
    for (var i = 0; i < found_partial.length; i++) {
      var part = found_partial[i];
      set_tag_html(part, ampere_hash, html);
      var found = part.querySelectorAll(selector(ampere_hash));
      for (var j = 0; j < found.length; j++) {
        var node = found[j];
        set_properties(node);
      };
    };
  } else {
    set_tag_html(document, ampere_hash, html);
    var found = document.querySelectorAll(selector(ampere_hash));
    for (var i = 0; i < found.length; i++) {
      var node = found[i];
      set_properties(node);
    };
  }
  Drab.set_event_handlers(selector(ampere_hash));
};

function update_script(ampere_hash, new_script, partial) {
  if (partial != null) {
    if (document.querySelector('[drab-partial=' + partial + '] ' + selector(ampere_hash)) != null) {
      eval(new_script);
    }
  } else {
    eval(new_script);
  }
}

Drab.update_tag = function (ampere_hash, html, partial, tag) {
  if (tag == "script") {
    update_script(ampere_hash, html, partial);
  } else {
    if (partial != null) {

      var found = document.querySelectorAll('[drab-partial=' + partial + ']');
      for (var i = 0; i < found.length; i++) {
        var part = found[i];
        set_tag_html(part, ampere_hash, html);
      };
    } else {
      set_tag_html(document, ampere_hash, html);
    }
  }
};

