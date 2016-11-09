defmodule Drab.Client do
  @moduledoc """
  Switch on Drab on the client side. Must be included in HTML template, for example 
  in `web/templates/layout/app.html.eex`:

      <%= Drab.Client.js(@conn) %>

  after the line which loads app.js:

      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
  """

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
      # TODO: script to template(?)
      Phoenix.HTML.raw """
      <script>
        require("web/static/js/drab").Drab.run('#{controller_and_action}')
        // require("drab").Drab.run('#{controller_and_action}')
      </script>
      """
    else 
      ""
    end
  end

end
