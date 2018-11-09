const MODAL_WRAPPER = "_drab_modal_wrapper_";
const MODAL_BUTTONS = ".drab-modal-button";

Drab.on_connect(function (resp, drab) {

  function modal_elems(id) {
    var modal_wrapper, modal, modal_backdrop, form;
    modal_wrapper = document.getElementById(MODAL_WRAPPER + id);
    if (modal_wrapper) {
      modal = modal_wrapper.querySelector(".modal")
      return {
        modal_wrapper: modal_wrapper,
        modal: modal,
        modal_backdrop: modal_wrapper.querySelector(".modal-backdrop"),
        form: modal.querySelector("form")
      }
    }
  }

  function clicked(message, element_name) {
    clearTimeout(Drab["modal_timeout_function_" + message.id]);
    var mod = modal_elems(message.id);
    if (mod) {
      var query_output = [message.sender, {
        button_clicked: element_name,
        params: Drab.form_params(mod.form)
      }];
      drab.channel.push("modal", { ok: query_output });

      mod.modal.className = "modal fade";
      mod.modal_backdrop.className = "modal-backdrop fade";
      setTimeout(function () {
        document.querySelector("body").classList.remove("modal-open");
        mod.modal_wrapper.outerHTML = "";
      }, 100);
    }
  }

  drab.channel.on("modal", function (message) {
    var mod = modal_elems(message.id);
    if (mod) mod.modal_wrapper.outerHTML = "";
    var body = document.querySelector("body");
    body.insertAdjacentHTML("beforeend", message.html);

    mod = modal_elems(message.id);
    setTimeout(function () {
      <%= case Drab.Config.get(:modal_css) do %>
        <% :bootstrap3 -> %> mod.modal.classList.add("in"); mod.modal_backdrop.classList.add("in");
        <% :bootstrap4 -> %> mod.modal.classList.add("show"); mod.modal_backdrop.classList.add("show");
      <% end %>
      body.classList.add("modal-open");
      mod.form.querySelector("input, textarea, select").focus();
    }, 50);

    var buttons = mod.modal.querySelectorAll(MODAL_BUTTONS);
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].onclick = function (e) { clicked(message, e.srcElement.getAttribute("name"));}
    }
    mod.form.onsubmit = function(e) {
      clicked(message, "ok");
      e.preventDefault();
      return false;
    };
    mod.form.onkeyup = function(e) {
      var key = e.which || e.keyCode;
      if (key == 27) {
        clicked(message, "cancel");
      }
    }
    if (message.timeout) {
      Drab["modal_timeout_function_" + message.id] = setTimeout(function () {
        clicked(message, "cancel");
      }, message.timeout);
    }
    Drab.enable_drab_on("#_drab_modal_wrapper_" + message.id + " .modal-body");
  });
});

