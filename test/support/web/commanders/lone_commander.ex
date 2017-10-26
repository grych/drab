defmodule DrabTestApp.LoneCommander do
  @moduledoc false
  import Drab.Core

  use Drab.Commander

  def lone_handler(socket, payload) do
    exec_js! socket, "document.getElementById('run_handler_test').innerHTML = '#{inspect(payload)}';"
    exec_js! socket, "document.getElementById('run_handler_test').payload = #{encode_js(payload)};"
  end
end
