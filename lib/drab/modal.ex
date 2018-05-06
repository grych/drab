defmodule Drab.Modal do
  require Logger
  import Drab.{Query, Template}

  @moduledoc """
  Drab Module to launch Bootstrap Modals in the browser.

  This module is optional and is not loaded by default. You need to explicitly declare it in the
  commander:

      use Drab.Commander, modules: [Drab.Modal]

  This module requires jQuery installed as global, see
  [README](https://hexdocs.pm/drab/readme.html#installation).
  """

  use DrabModule
  @impl true
  def prerequisites(), do: [Drab.Query]
  @impl true
  def js_templates(), do: ["drab.modal.js"]

  @doc """
  Modal, synchronous alert box. This function shows bootstrap modal window on the browser and waits
  for the user input.

  Parameters:
  * title - title of the message box
  * body - html with the body of the alert box. When contains input, selects, etc, this function
  return their values

  Options:
  * class - additional classes to .modal-dialog, ex. modal-lg, modal-sm, modal-xs
  * buttons - list of name/text of the buttons (:ok, :cancel are only available names by default;
    you need to create a template if you want more buttons), eq. [ok: "Yes", cancel: "No"]
  * timeout - in milliseconds - after this time modal window will close and the function will
    return {:cancel, _}

  Returns a tuple {clicked_button, params}, where:
  * clicked_button is an atom of `:ok` or `:cancel`. Notice that pressing `esc` or closing
    the modal window will return :cancel, while pressing `enter` returns :ok
  * params: Map `%{name|id => value}` of all inputs, selects, etc which are in the alert box body.
    Uses `name` attribute as a key, or `id`, when there is no `name`, or `__undefined_[number]`,
    when neither `id` or `name` are specified.

  Examples:

      socket |> alert("Title", "Shows this message with default OK button")

      # Yes/No requester, returns :ok or :cancel
      {button, _} = socket |> alert("Message", "Sure?", buttons: [ok: "Azaliż", cancel: "Ney"])

      # messagebox with two input boxes in body
      form = "<input name='first'><input id='second'>"
      name = case socket |> alert("What's your name?", form, buttons: [ok: "OK", cancel: "No"]) do
        { :ok, params } -> "\#{params["first"]} \#{params["second"]}"
        { :cancel, _ }  -> "anonymous"
      end

  Templates used to generate HTML for the alert box could be found in
  `deps/drab/priv/templates/drab/`. If you want to modify it, copy them to `priv/templates/drab`
  in your application. There are two templates for default `:ok` and `:cancel` buttons, but
  you may create new one and use them in the same way. For example, to have a new button called
  `unspecified` create a template `priv/templates/drab/modal.alert.button.unspecified.html.eex`:

      <button id="_drab_modal_button_unspecified" name="unspecified" type="button"
       class="btn btn-default drab-modal-button" data-dismiss="modal">
          <%= label %>
      </button>

  The button must have `drab-modal-button` class and its name should correspond to key in `buttons`
  list. Now you can use your button in the same way as `:ok` and `:cancel`

      {button, _} =
        socket |> alert("3 buttons", "Choice?",
                  buttons: [ok: "Yes", cancel: "No", unspecified: "Don't know"])

  """
  @spec alert(Phoenix.Socket.t(), String.t(), String.t(), Keyword.t()) :: Drab.Core.return()
  @spec alert(Phoenix.Socket.t(), String.t(), String.t()) :: Drab.Core.return()
  def alert(socket, title, body, options \\ []) do
    buttons = options[:buttons] || [ok: "OK"]

    bindings = [
      title: title,
      body: body,
      class: options[:class],
      buttons: buttons_html(buttons)
    ]

    html = render_template("modal.alert.html.eex", bindings)

    socket
    |> delete("#_drab_modal")
    |> insert(html, append: "body")

    {:ok, result} =
      Drab.push_and_wait_forever(socket, self(), "modal", timeout: options[:timeout])

    result
  end

  @spec buttons_html(Keyword.t()) :: String.t()
  defp buttons_html(buttons) do
    buttons
    |> Enum.map(fn {button, label} ->
      render_template("modal.alert.button.#{Atom.to_string(button)}.html.eex", label: label)
    end)
    |> Enum.join("\n")
  end
end
