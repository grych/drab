Drab.add_payload(function(sender, event) {
  return {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes,
    __index:   __drab.index
  }
})

function set_property(node, attribute_name, attribute_value) {
  var property = node.getAttribute("@" + attribute_name).replace(/{{{{.+}}}}$/, "")
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
  d.amperes = {}
  document.querySelectorAll("[drab-partial]").forEach(function(partial) {
    var partial_id = partial.getAttribute("drab-partial")
    d.amperes[partial_id] = []
  })
  document.querySelectorAll("[drab-partial] [drab-ampere]").forEach(function(node) {
    var drab_id = node.getAttribute("drab-ampere")
    var partial = closest(node, function(el) {
      return el.hasAttribute("drab-partial")
    })
    var partial_id = partial.getAttribute("drab-partial")
    if (d.amperes[partial_id].indexOf(drab_id) < 0) {
      d.amperes[partial_id].push(drab_id)
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
  // get the name of the main partial
  d.index = document.querySelector("[drab-partial]").getAttribute("drab-partial")
})

function set_attr(where, selector, attribute_name, new_value) {
  where.querySelectorAll(selector).forEach(function(node) {
    node.setAttribute(attribute_name, new_value)
  })
}

Drab.update_attr = function(selector, attribute_name, new_value, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_attr(part, selector, attribute_name, new_value)
    })
  } else {
    set_attr(document, selector, attribute_name, new_value)
  }
}

function set_prop(where, selector, property_name, new_value) {
  where.querySelectorAll(selector).forEach(function(node) {
    set_property(node, property_name, new_value)
  })
}

Drab.update_prop = function(selector, property_name, new_value, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_prop(part, selector, property_name, new_value)
    })
  } else {
    set_prop(document, selector, property_name, new_value)
  }
}

function set_drab_span(where, selector, html) {
  where.querySelectorAll(selector).forEach(function(node) {
    node.innerHTML = html
  })
}

Drab.update_drab_span = function(selector, html, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_drab_span(part, selector, html)
    })
  } else {
    set_drab_span(document, selector, html)
  }
}

Drab.update_script = function(selector, new_script, partial) {
  if (partial != null) {
    if (document.querySelector('[drab-partial=' + partial + '] ' + selector) != null) {
      eval(new_script)
    }
  } else {
    eval(new_script)
  }
}
