function get_element_attributes(element) {
  var ret = {};
  for (var i = 0; i < element.attributes.length; i++) {
    var att = element.attributes[i];
    ret[att.name] = att.value;
  }
  return ret;
}

function to_array(dom_list) {
  var ret = [];
  for (var i = 0; i < dom_list.length; i++) {
    ret.push(dom_list[i]);
  }
  return ret;
}

function to_map(element) {
  var ret = {};
  for (var key in element) {
    if (element[key]) {
      ret[key] = element[key];
    }
  }
  return ret;
}

function default_properties(element) {
  return {
    drab_id: element.getAttribute("drab-id"),
    id: element.id,
    attributes: get_element_attributes(element),
    className: element.className,
    classList: to_array(element.classList),
    // clientHeight: element.clientHeight, //int
    // clientLeft:   element.clientLeft,
    // clientTop:    element.clientTop,
    // clientWidth:  element.clientWidth,
    // contentEditable: element.contentEditable,
    dataset: element.dataset,
    // dir:          element.dir,
    // lang:         element.lang,
    // offsetHeight: element.offsetHeight,
    // offsetLeft:   element.offsetLeft,
    // offsetParent: element.offsetParent,
    // offsetTop:    element.offsetTop,
    // offsetWidth:  element.offsetWidth,
    // id:           element.id,
    innerHTML: element.innerHTML,
    innerText: element.innerText,
    // localName:    element.localName,
    name: element.name,
    // outerHTML:    element.outerHTML,
    // outerText:    element.outerText,
    // scrollHeight: element.scrollHeight,
    // scrollLeft:   element.scrollLeft,
    // scrollTop:    element.scrollTop,
    // scrollWidth:  element.scrollWidth,
    style: to_map(element.style),
    tagName: element.tagName,
    // tabIndex:     element.tabIndex,
    // title:        element.title,
    // defaultValue: element.defaultValue,
    // disabled:     element.disabled,
    // maxLength:    element.maxLength,
    // readOnly:     element.readOnly,
    // size:         element.size,
    // type:         element.type,
    value: element.value
  };
}

Drab.query = function (selector, what, where) {
  var searchie = where || document;
  var ret = {};
  var found = searchie.querySelectorAll(selector);
  for (var i = 0; i < found.length; i++) {
    var element = found[i];
    var id = element.id;
    var id_selector;
    if (id) {
      id_selector = "#" + id;
    } else {
      var drab_id = Drab.setid(element);
      id_selector = "[drab-id='" + drab_id + "']";
    }
    ret[id_selector] = {};
    if (what.length != 0) {
      for (var j in what) {
        var property = what[j];
        switch (property) {
          case "attributes":
            ret[id_selector][property] = get_element_attributes(element);
            break;
          case "style":
            ret[id_selector][property] = to_map(element.style);
            break;
          case "classList":
            ret[id_selector][property] = to_array(element.classList);
            break;
          case "options":
            var options = element.options;
            if (options instanceof HTMLOptionsCollection) {
              var ret_options = {};
              for (var j = 0; j < options.length; j++) {
                ret_options[options[j].value] = options[j].text;
              }
              ret[id_selector][property] = ret_options;
            } else {
              ret[id_selector][property] = element.options;
            }
            break;
          default:
            ret[id_selector][property] = element[property];
            break;
        }
      }
    } else {
      ret[id_selector] = default_properties(element);
    }
  };
  return ret;
};

function isObject(val) {
  if (val === null) {
    return false;
  }
  return typeof val === 'function' || typeof val === 'object';
}

Drab.set_prop = function (selector, what, where) {
  var searchie = where || document;
  var i = 0;
  var found = searchie.querySelectorAll(selector);
  for (i = 0; i < found.length; i++) {
    var element = found[i];
    for (var property in what) {
      var value = what[property];
      switch (property) {
        case "attributes":
          for (var p in value) {
            element.setAttribute(p, value[p]);
          }
          break;
        case "style":
          for (var p in value) {
            element[property][p] = value[p];
          }
          break;
        case "dataset":
          for (var p in value) {
            element[property][p] = value[p];
          }
          break;
        case "innerHTML":
          element[property] = what[property];
          Drab.enable_drab_on(selector);
          break;
        case "outerHTML":
          var parent = element.parentNode;
          element[property] = what[property];
          Drab.enable_drab_on(parent);
          break;
        case "options":
          if (element.options instanceof HTMLOptionsCollection) {
            element.length = 0;
            for (var p in value) {
              var option = document.createElement("option");
              option.value = p;
              option.text = value[p];
              element.add(option);
            }
          } else {
            element[property] = what[property];
          }
          break;

        default:
          element[property] = what[property];
          break;
      }
    }
  };
  return i;
};

Drab.insert_html = function (selector, position, html, where) {
  var searchie = where || document;
  var i = 0;
  var found = searchie.querySelectorAll(selector);
  for (i = 0; i < found.length; i++) {
    var element = found[i];
    element.insertAdjacentHTML(position, html);
  };
  Drab.enable_drab_on(selector);
  return i;
};

