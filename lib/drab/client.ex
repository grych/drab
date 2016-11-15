defmodule Drab.Client do
  @moduledoc """
  Switch on Drab on the client side. Must be included in HTML template, for example 
  in `web/templates/layout/app.html.eex`:

      <%= Drab.Client.js(@conn) %>

  after the line which loads app.js:

      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
  """

  import Drab.Templates

  @doc """
  Generates JS code which runs Drab. Passes controller and action name, tokenized for safety.
  Runs only when the controller which renders current action has been compiled
  with `use Drab.Controller`
  """
  def js(conn) do
    controller = Phoenix.Controller.controller_module(conn)
    # Enable Drab only if Controller compiles with `use Drab.Controller`
    # in this case controller contains function `__drab__/0`
    if Enum.member?(controller.__info__(:functions), {:__drab__, 0}) do
      controller_and_action = Phoenix.Token.sign(conn, "controller_and_action", 
                              "#{controller}##{Phoenix.Controller.action_name(conn)}")
      bindings = [
        controller_and_action: controller_and_action
      ]
      js = render_template("drab.js", bindings)

      Phoenix.HTML.raw """
      <script>
        #{js}
      </script>
      """
    else 
      ""
    end
  end

end
