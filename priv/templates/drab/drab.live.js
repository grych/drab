Drab.add_payload(function(sender, event) {
  return {
    __assigns: __drab.assigns,
    __amperes: __drab.amperes
  }
})

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
})

Drab.update_attribute = function(selector, attribute, new_value) {
  node = document.querySelector(selector)
  node.setAttribute(attribute, new_value)
}

Drab.update_drab_span = function(selector, html) {
  document.querySelectorAll(selector).forEach(function(node) {
    node.innerHTML = html
  })
}

Drab.update_script = function(selector, new_script) {
  eval(new_script)
}
