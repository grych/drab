defmodule Drab.Client do
  def js(conn) do
    controller_and_action = Cipher.encrypt("#{Phoenix.Controller.controller_module(conn)}##{Phoenix.Controller.action_name(conn)}")
    Phoenix.HTML.raw """
    <script>
      require("web/static/js/drab").Drab.run('#{controller_and_action}')
    </script>
    """
  end
end
