Drab.add_payload(function(sender, event) {
  return {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes
  }
})

function set_property(node, attribute_name, attribute_value) {
  var property = node.getAttribute("@" + attribute_name)
  var path = property.split(".")
  var full = node
  var prev, last
  path.forEach(function(part) {
    prev = full
    full = full[part]
    last = part
  })
  prev[last] = attribute_value
}

Drab.on_load(function(resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  var d = window.__drab
  d.amperes = []
  document.querySelectorAll("[drab-ampere]").forEach(function(node) {
    var drab_id = node.getAttribute("drab-ampere")
    if (d.amperes.indexOf(drab_id) < 0) {
      d.amperes.push(drab_id)
    }
  })
  // update the properties set in <tag @property=expression>
  for (var ampere in d.properties) {
    var properties = d.properties[ampere]
    for (var i = 0; i < properties.length; i ++) {
      for (key in properties[i]) {
        var node = document.querySelector("[drab-ampere='" + ampere + "']")
        // node.removeAttribute("$" + key)
        // node[key] = properties[i][key]
        set_property(node, key, properties[i][key])
      }
    }
  }
})

Drab.update_attr = function(selector, attribute_name, new_value) {
  node = document.querySelector(selector)
  node.setAttribute(attribute_name, new_value)
}

Drab.update_prop = function(selector, property_name, new_value) {
  node = document.querySelector(selector)
  set_property(node, property_name, new_value)
}

Drab.update_drab_span = function(selector, html) {
  document.querySelectorAll(selector).forEach(function(node) {
    node.innerHTML = html
  })
}

Drab.update_script = function(selector, new_script) {
  eval(new_script)
}
