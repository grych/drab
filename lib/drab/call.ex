defmodule Drab.Call do
  require Logger
  import Drab.Query

  @moduledoc """
  Call contains functions used to communicate from the server back to the browser.
  """

  @doc """
  Modal, synchronous alert box. This functions shows bootstrap modal window on the browser and waits for the user input.

  Options:
  * title - title of the message box
  * body - html with the body of the alert box. When contains input, selects etc functions returns their values
  * buttons - names of the buttons (:ok, :cancel are only available), like ok: "Yes", cancel: "No"

  Returns a tuple {clicked_button, params}, where:
  * clicked_button is an atom of `:ok` or `:cancel`. Notice that pressing `esc` or closing the modal window will 
    return :cancel, while pressing `enter` returns :ok
  * params: Map `%{name|id => value}` of all inputs, selects, etc which are in the alert box body. Uses `name` 
    attribute as a key (or `id` when there is no `name`, or `undefined`).

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
  def alert(socket, title, body, buttons \\ [ok: "OK"]) do
    # TODO: move it to template
    html = """
    <div id="_drab_modal" class="modal fade" tabindex="-1" role="dialog">
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
            <h4 class="modal-title">#{title}</h4>
          </div>
          <div class="modal-body">
            <form>
              <p>#{body}</p>
            </form>
          </div>
          <div class="modal-footer">
            #{buttons_html(buttons)}
          </div>
        </div><!-- /.modal-content -->
      </div><!-- /.modal-dialog -->
    </div><!-- /.modal -->
    """
    socket |> delete("#_drab_modal")
    socket |> insert(html, append: "body")

    Phoenix.Channel.push(socket, "modal",  %{sender: tokenize(socket, self())})

    receive do
      {:got_results_from_client, reply} ->
        reply
    end

  end

  defp buttons_html(buttons) do
    "" <> 
    if buttons[:ok] do
      """
      <button id="_drab_modal_button_ok" type="submit" class="btn btn-primary" data-dismiss="modal">#{buttons[:ok]}</button>
      """
    else 
      ""
    end <>
    if buttons[:cancel] do
      """
      <button id="_drab_modal_button_cancel" type="button" class="btn btn-danger" data-dismiss="modal">#{buttons[:cancel]}</button>
      """
    else 
      ""
    end
  end
end
