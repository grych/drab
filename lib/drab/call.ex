defmodule Drab.Call do
  require Logger
  import Drab.Query
  import Drab.Templates

  @moduledoc """
  Call contains functions used to communicate from the server back to the browser.
  """

  @doc """
  Modal, synchronous alert box. This functions shows bootstrap modal window on the browser and waits for the user input.

  Parameters and options:
  * title - title of the message box
  * body - html with the body of the alert box. When contains input, selects, etc, this function return their values
  * class - additional classes to .modal-dialog, ex. modal-lg, modal-sm, modal-xs
  * buttons - names of the buttons (:ok, :cancel are only available), like ok: "Yes", cancel: "No"

  Returns a tuple {clicked_button, params}, where:
  * clicked_button is an atom of `:ok` or `:cancel`. Notice that pressing `esc` or closing the modal window will 
    return :cancel, while pressing `enter` returns :ok
  * params: Map `%{name|id => value}` of all inputs, selects, etc which are in the alert box body. Uses `name` 
    attribute as a key (or `id` when there is no `name`, or `undefined`).

  Templates used to generate HTML for the alert box could be found in `deps/drab/priv/templates/drab/`. If you want to
  modify it, copy them to `priv/templates/drab` in your application.
  There are two templates for default `:ok` and `:cancel` buttons, but you may create new one and use them in the same
  way.

  Examples:

      socket |> alert("Title", "Shows this message with default OK button")

      # Yes/No requester, returns :ok or :cancel
      {button, _} = socket |> alert("Message", "Sure?", ok: "Azaliż", cancel: "Poniechaj")
      
      # messagebox with two input boxes in body
      form = "<input name='first'><input id='second'>"
      name = case socket |> alert("What's your name?", form, ok: "OK", cancel: "Cancel") do
        { :ok, params } -> "\#{params["first"]} \#{params["second"]}"
        { :cancel, _ }  -> "anonymous"
      end
      
  """
  def alert(socket, title, body, class, buttons) do
    bindings = [
      title: title,
      body: body,
      class: class,
      buttons: buttons_html(buttons)
    ]
    html = render_template("call.alert.html.eex", bindings)

    socket |> delete("#_drab_modal")
    socket |> insert(html, append: "body")

    Phoenix.Channel.push(socket, "modal",  %{sender: tokenize(socket, self())})

    receive do
      {:got_results_from_client, reply} ->
        reply
    end    
  end
  @doc """
  Launches `Drab.Call.query/5` without additional classes
  """
  def alert(socket, title, body, buttons) when is_list(buttons) do
    alert(socket, title, body, "", buttons)
  end
  @doc """
  Launches `Drab.Call.query/5` with default OK button and additional classes
  """
  def alert(socket, title, body, class) when is_binary(class) do
    alert(socket, title, body, class, [ok: "OK"])
  end
  @doc """
  Launches `Drab.Call.query/4` with default OK button
  """
  def alert(socket, title, body) do
    alert(socket, title, body, [ok: "OK"])
  end

  defp buttons_html(buttons) do
    Enum.map(buttons, fn {button, label} -> 
      render_template("call.alert.button.#{Atom.to_string(button)}.html.eex", [label: label])
    end) |> Enum.join("\n")
  end
end
