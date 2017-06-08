// function find_amperes_by_assign(assign) {
//   var spans = document.querySelectorAll("span[drab-assigns~='" + assign + "']")
//   var ret = []
//   // for (var i = 0; i < spans.length; ++i) {
//   //   var span = spans[i]
//   spans.forEach(function(span) {
//     ret.push({
//       id:         span.getAttribute("id"),
//       drab_expr:  span.getAttribute("drab-expr"),
//       assigns:    span.getAttribute("drab-assigns")
//     })
//   })
//   return ret
// }


// Drab.find_amperes_by_assigns = function(assign_list) {
//   var ret = []
//   assign_list.forEach(function(assign) {
//   // for (var i = 0; i < assign_list.length; ++i) {
//   //   var assign = assign_list[i]
//     amperes = find_amperes_by_assign(assign)
//     amperes.forEach(function(ampere) {
//     // for (var j = 0; j < amperes.length; ++j) {
//       // var ampere = amperes[j]
//       if (ret.indexOf(ampere) < 0) {
//         ret.push(ampere)
//       }
//     })
//   })
//   return {amperes: ret, current_assigns: __drab.assigns}
// }

// function find_injects_by_assign(assign) {
//   var nodes = document.querySelectorAll("[__drabbed]")
//   var ret = []
//   nodes.forEach(function(node) {
//     ret.push({
//       drab_id:  node.getAttribute("drab-id")
//     })
//   })
//   return ret
// }

// Drab.find_injects_by_assigns = function(assign_list) {
//   var ret = []
//   assign_list.forEach(function(assign) {
//     injects = find_injects_by_assign(assign)
//     injects.forEach(function(inject) {
//       if (ret.indexOf(inject) < 0) {
//         ret.push(inject)
//       }
//     }) 
//   })
//   return ret
// }

Drab.add_payload(function(sender, event) {
  return {
    assigns: __drab.assigns,
    amperes: __drab.amperes
  }
})

Drab.on_load(function(resp, drab) {
  // add drab-id to all drabbed tags
  var drabbed = document.querySelectorAll("[__drabbed]")
  // drabbed.forEach(function(node) {
    // Drab.setid(node)
    // 
  // })
  // extract information from all drabbed nodes and store it in global __drab
  var d = window.__drab
  d.amperes = []
  document.querySelectorAll("[drab-id]").forEach(function(node) {
    var drab_id = node.getAttribute("drab-id")
    if (d.amperes.indexOf(drab_id) < 0) {
      d.amperes.push(drab_id)
    }
  })

  // d.amperes.injected = {}
  // d.amperes.attributed = {}
  // drabbed.forEach(function(node) {
  //   if (node.getAttribute("__drabbed") == "ampere") {
  //     // injected spans
  //     var assigns = node.getAttribute("drab-assigns")
  //       if (!(assigns in d.amperes.injected)) {
  //         d.amperes.injected[assigns] = []
  //       }
  //       d.amperes.injected[assigns].push({
  //         id:         node.getAttribute("id"),
  //         drab_expr:  node.getAttribute("drab-expr")
  //       })
  //   } else {
  //     // attribute
  //     Drab.setid(node)
  //     var drab_id = node.getAttribute("drab-id")
  //     d.amperes.attributed[drab_id] = {}
  //     // console.log(node)
  //     for (var i = 0; i < node.attributes.length; i++) {
  //       var attr = node.attributes[i]
  //       // console.log(attr)
  //       if (attr.name.startsWith("drab-assigns")) {
  //         // console.log(attr)
  //         var assigns = attr.value
  //         if (!(assigns in d.amperes.attributed)) {
  //           d.amperes.attributed[drab_id][assigns] = []
  //         }
  //         var expr = attr.name.replace("drab-assigns-", "")
  //         d.amperes.attributed[drab_id][assigns].push({
  //           // id:        node.getAttribute("id"),
  //           drab_expr: expr,
  //           attribute: node.getAttribute("drab-attribute-" + expr)
  //         })
  //       }
  //     }
  //   }
  // })
})
