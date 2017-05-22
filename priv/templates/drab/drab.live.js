function find_amperes_by_assign(assign) {
  var spans = document.querySelectorAll("[drab-assigns~='" + assign + "']")
  var ret = []
  for (var i = 0; i < spans.length; ++i) {
    var span = spans[i]
    ret.push({
      id:         span.getAttribute("id"),
      drab_expr:  span.getAttribute("drab-expr"),
      assigns:    span.getAttribute("drab-assigns")
    })
  }
  return ret
}

function get_assigns() {
  return __drab.assigns
}

Drab.find_amperes_by_assigns = function(assign_list) {
  var ret = []
  for (var i = 0; i < assign_list.length; ++i) {
    var assign = assign_list[i]
    amperes = find_amperes_by_assign(assign)
    for (var j = 0; j < amperes.length; ++j) {
      var ampere = amperes[j]
      if (ret.indexOf(ampere) < 0) {
        ret.push(ampere)
      }
    }
  }
  return {amperes: ret, current_assigns: get_assigns()}
}

