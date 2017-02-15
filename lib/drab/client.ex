defmodule Drab.Client do
  @moduledoc """
  Enable Drab on the browser side. Must be included in HTML template, for example 
  in `web/templates/layout/app.html.eex`:

      <%= Drab.Client.js(@conn) %>

  after the line which loads app.js:

      <script src="<%= static_path(@conn, "/js/app.js") %>"></script>
  """

  import Drab.Template
  require Logger

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
      commander = controller.__drab__()[:commander]
      modules = [Drab.Core | commander.__drab__().modules] # Drab.Core is included by default
      templates = Enum.map(modules, fn x -> "#{Module.split(x) |> Enum.join(".") |> String.downcase()}.js" end)

      access_store = commander.__drab__().inherit_session
      store = access_store 
        |> Enum.map(fn x -> {x, Plug.Conn.get_session(conn, x)} end) 
        |> Enum.into(%{})

      store_token = Drab.tokenize_store(conn, store)

      bindings = [
        controller_and_action: controller_and_action,
        commander: commander,
        templates: templates,
        drab_store_token: store_token
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
