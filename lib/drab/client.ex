defmodule Drab.Client do
  def js(conn) do
    controller = Phoenix.Controller.controller_module(conn)
    # Enable Drab only if Controller compiles with `use Drab.Controller`
    # in this case controller contains function `__drab__/0`
    if Enum.member?(controller.__info__(:functions), {:__drab__, 0}) do
      controller_and_action = Phoenix.Token.sign(conn, "controller_and_action", 
                              "#{controller}##{Phoenix.Controller.action_name(conn)}")
      Phoenix.HTML.raw """
      <script>
        require("web/static/js/drab").Drab.run('#{controller_and_action}')
      </script>
      """
    else 
      ""
    end
  end
end
