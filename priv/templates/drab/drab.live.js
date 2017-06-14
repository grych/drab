Drab.add_payload(function(sender, event) {
  return {
    assigns: __drab.assigns,
    amperes: __drab.amperes,
    scripts: __drab.scripts
  }
})

Drab.on_load(function(resp, drab) {
  // add drab-expr to all drabbed tags
  // collect attributed values
  var drabbed = document.querySelectorAll("[drabbed]")
  drabbed.forEach(function(node) {
    var hashes = []
    node.removeAttribute("drabbed")
    for (var i = 0; i < node.attributes.length; i++) {
      var attr = node.attributes[i]
      if (attr.name.startsWith("drab-attr")) {
        var hash = attr.name.replace("drab-attr-", "")
        if (hashes.indexOf(hash) < 0) {
          node.removeAttribute(attr.name)
          hashes.push(hash)
        }
      }
    }
    if (hashes.length > 0) {
      node.setAttribute("drab-expr", hashes.join(" "))
    }
  })

  // extract information from all drabbed nodes and store it in global __drab
  var d = window.__drab
  d.amperes = []
  document.querySelectorAll("[drab-expr]").forEach(function(node) {
    var drab_id = node.getAttribute("drab-expr")
    if (d.amperes.indexOf(drab_id) < 0) {
      d.amperes.push(drab_id)
    }
  })

  var scripted = document.querySelectorAll("[drab-script]")
  d.scripts = []
  scripted.forEach(function(node) {
    var drab_id = node.getAttribute("drab-script")
    if (d.scripts.indexOf(drab_id) <0) {
      d.scripts.push(drab_id)
    }
  })
})

Drab.update_attribute = function(selector, attribute, current_value, new_value, prefix) {
  // "document.querySelectorAll(\"#{selector}\").forEach(function(n) {n.setAttribute('#{attribute}', #{js})})"
  document.querySelectorAll(selector).forEach(function(node) {
    var current = node.getAttribute(attribute)
    var suffix = current.replace(prefix, "")
    var replaced = suffix.replace(current_value, new_value)
    node.setAttribute(attribute, prefix + replaced)
  })
}

Drab.update_drab_span = function(selector, html) {
  document.querySelectorAll(selector).forEach(function(node) {
    node.innerHTML = html
  })
}
