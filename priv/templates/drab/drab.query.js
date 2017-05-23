// const EVENTS = ["click", "change", "keyup", "keydown"]
// const EVENTS_TO_DISABLE = <%= Drab.Config.get(:events_to_disable_while_processing) |> Drab.Core.encode_js %>

// disable all drab object when disconnected from the server
// Drab.disable_drab_objects = function(disable) {
//   <%= if Drab.Config.get(:disable_controls_when_disconnected) do %>
//     $("[drab-event]").prop('disabled', disable)
//   <% end %>
// }


// //http://davidwalsh.name/javascript-debounce-function
// function debounce(func, wait, immediate) {
//     var timeout;
//     return function() {
//         var context = this, args = arguments;
//         var later = function() {
//             timeout = null;
//             if (!immediate) func.apply(context, args);
//         };
//         var callNow = immediate && !timeout;
//         clearTimeout(timeout);
//         timeout = setTimeout(later, wait);
//         if (callNow) func.apply(context, args);
//     };
// };

// function payload(who, event) {
//   setid(who)
//   return {
//     // by default, we pass back some sender attributes
//     id:     who.attr("id"),
//     name:   who.attr("name"),
//     class:  who.attr("class"),
//     text:   who.text(),
//     html:   who.html(),
//     val:    who.val(),
//     data:   who.data(),
//     drab_id: who.attr("drab-id"),
//     event:  extract_from_event(event)
//   }
// }

// function extract_from_event(event) {
//   return {
//     altKey: event.altKey,
//     data: event.data,
//     key: event.key,
//     keyCode: event.keyCode,
//     metaKey: event.metaKey,
//     shiftKey: event.shiftKey,
//     ctrlKey: event.ctlrKey,
//     type: event.type,
//     which: event.which,
//     clientX: event.clientX,
//     clientY: event.clientY,
//     offsetX: event.offsetX,
//     offsetY: event.offsetY,
//     pageX: event.pageX,
//     pageY: event.pageY,
//     screenX: event.screenX,
//     screenY: event.screenY
//   }
// }

// function setid(whom) {
//   whom.attr("drab-id", uuid())
// }

// // set up the controls with drab handlers
// Drab.set_event_handlers = function(obj) {
//   var $drab_objects
//   var $drab_objects_shortcut

//   // first serve the shortcut controls by adding the longcut attrbutes
//   EVENTS.forEach(function(ev) {
//     $drab_objects_shortcut = obj ? $(obj).parent().find("[drab-" + ev + "]") : $("[drab-" + ev + "]")
//     // console.log($drab_objects_shortcut)
//     $drab_objects_shortcut.each(function() {
//       $(this).attr("drab-event", ev) 
//       $(this).attr("drab-handler", $(this).attr("drab-" + ev))
//     })
//   })

//   $drab_objects = obj ? $(obj).parent().find("[drab-event]") : $("[drab-event]")

//   var events_to_disable = EVENTS_TO_DISABLE
//   $drab_objects.each(function() {
//     if($(this).attr("drab-handler")) {

//       var event_handler_function = function(event) {
//         var t = $(this)
//         // disable current control - will be re-enabled after finish
//         <%= if Drab.Config.get(:disable_controls_while_processing) do %>
//           if ($.inArray(event_name, events_to_disable) >= 0) {
//             t.prop('disabled', true)
//           }
//         <% end %>
//         // console.log(event)
//         // send the message back to the server
//         Drab.run_handler(
//           event_name, 
//           t.attr("drab-handler"), 
//           payload(t, event)
//           <%= if Drab.Config.get(:disable_controls_while_processing) do %>
//             ,
//             function() {
//               t.prop('disabled', false)
//               // console.log("GOTREPLY!", t)
//             }
//           <% end %>
//           )
//       }

//       var event_name=$(this).attr("drab-event")
//       // console.log(event_name, obj)

//       // options. Wraps around event_handler_function, eg. debounce(event_handler_function, 500)
//       var options = $(this).attr("drab-options")
//       matched = /(\w+)\s*\((.*)\)/.exec(options)
//       if(matched) {
//         var fname = matched[1]
//         var fargs = matched[2].replace(/^\s+|\s+$/g, '') // strip whitespace
//         var f = fname + "(event_handler_function" + (fargs == "" ? "" : ", " + fargs) + ")"
//         $(this).off(event_name).on(event_name, eval(f))        
//       } else {
//         $(this).off(event_name).on(event_name, event_handler_function)         
//       }

//     } else {
//       console.log("Drab Error: drab-event definded without drab-handler", $(this))
//     }
//   })  
// }

// Drab.on_load(function(drab) {
//   drab.disable_drab_objects(true)
// })

// Drab.on_disconnect(function(drab) {
//   drab.disable_drab_objects(true)
// })

// Drab.on_connect(function(resp, drab) {
//   drab.set_event_handlers()

//   // re-enable drab controls
//   drab.disable_drab_objects(false)
// })
