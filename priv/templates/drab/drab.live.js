Drab.add_payload(function(sender, event) {
  return {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes,
    __index:   __drab.index
  }
})

Drab.on_load(function(resp, drab) {
  // extract information from all drabbed nodes and store it in global __drab
  if (typeof window.__drab == 'undefined') {window.__drab = {assigns: {}}};
  var d = window.__drab
  d.amperes = {}
  d.properties = {}
  document.querySelectorAll("[drab-partial]").forEach(function(partial) {
    var partial_id = partial.getAttribute("drab-partial")
    d.amperes[partial_id] = []
  })
  document.querySelectorAll("[drab-partial]").forEach(function (node) {
    var partial_name = node.getAttribute("drab-partial")
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
  set_properties(document)
  // get the name of the main partial
  if (document.querySelector("[drab-partial]")) {
    d.index = document.querySelector("[drab-partial]").getAttribute("drab-partial")
  }
})

function set_properties(where) {
  var d = window.__drab
  where.querySelectorAll("[drab-ampere]").forEach(function(node) {
    // find the properties
    var drab_id = node.getAttribute("drab-ampere")
    d.properties[drab_id] = []
    for (var i=0; i < node.attributes.length; i++) {
      var attr_name = node.attributes[i].name
      if (attr_name.startsWith("@")) {
        var p = {}
        p[attr_name.replace(/^@/, "")] = JSON.parse(
          node.attributes[i].value.replace(/^[^{]*{{{{/, "").replace(/}}}}$/, ""))
        d.properties[drab_id].push(p)
      }
    }
  })
  for (var ampere in d.properties) {
    var properties = d.properties[ampere]
    for (var i = 0; i < properties.length; i ++) {
      for (key in properties[i]) {
        where.querySelectorAll("[drab-ampere='" + ampere + "']").forEach(function(node) {
          set_property(node, key, properties[i][key])          
        })
      }
    }
  }
}

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

function selector(ampere_hash) {
  return "[drab-ampere='" + ampere_hash + "']"
}

function set_attr(where, ampere_hash, attribute_name, new_value) {
  where.querySelectorAll(selector(ampere_hash)).forEach(function(node) {
    node.setAttribute(attribute_name, new_value)
    // exception for "value", set the property as well
    //TODO: full list of exceptions
    if (attribute_name == "value") {
      node.value = new_value
    }
  })
}

Drab.update_attr = function(ampere_hash, attribute_name, new_value, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_attr(part, ampere_hash, attribute_name, new_value)
    })
  } else {
    set_attr(document, ampere_hash, attribute_name, new_value)
  }  
}

function set_prop(where, ampere_hash, property_name, new_value) {
  where.querySelectorAll(selector(ampere_hash)).forEach(function(node) {
    set_property(node, property_name, new_value)
  })
}

Drab.update_prop = function(ampere_hash, property_name, new_value, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_prop(part, ampere_hash, property_name, new_value)
    })
  } else {
    set_prop(document, ampere_hash, property_name, new_value)
  }
}

function set_tag_html(where, ampere_hash, html) {
  where.querySelectorAll(selector(ampere_hash)).forEach(function(node) {
    node.innerHTML = html
  })
}

Drab.update_drab_span = function(ampere_hash, html, partial) {
  if (partial != null) {
    document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
      set_tag_html(part, ampere_hash, html)
      part.querySelectorAll(selector(ampere_hash)).forEach(function(node) {
        set_properties(node)
      })
    })
  } else {
    set_tag_html(document, ampere_hash, html)
    document.querySelectorAll(selector(ampere_hash)).forEach(function(node) {
      set_properties(node)
    })
  }
  Drab.set_event_handlers(selector(ampere_hash))
}

function update_script(ampere_hash, new_script, partial) {
  if (partial != null) {
    if (document.querySelector('[drab-partial=' + partial + '] ' + selector(ampere_hash)) != null) {
      eval(new_script)
    }
  } else {
    eval(new_script)
  }
}

Drab.update_tag = function(ampere_hash, html, partial, tag) {
  if (tag == "script") {
    update_script(ampere_hash, html, partial)
  } else {
    if (partial != null) {
      document.querySelectorAll('[drab-partial=' + partial + ']').forEach(function(part) {
        set_tag_html(part, ampere_hash, html)
      })
    } else {
      set_tag_html(document, ampere_hash, html)
    }
  }
}
