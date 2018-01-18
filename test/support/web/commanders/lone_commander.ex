defmodule DrabTestApp.LoneCommander do
  @moduledoc false
  import Drab.Core

  use Drab.Commander

  public(:lone_handler)
  before_handler(:check_permissions)

  def lone_handler(socket, payload) do
    exec_js!(
      socket,
      "document.getElementById('run_handler_test').innerHTML = '#{inspect(payload)}';"
    )

    exec_js!(
      socket,
      "document.getElementById('run_handler_test').payload = #{encode_js(payload)};"
    )
  end

  def non_public_handler(socket, payload) do
    exec_js!(
      socket,
      "document.getElementById('run_handler_test').innerHTML = '#{inspect(payload)}';"
    )

    exec_js!(
      socket,
      "document.getElementById('run_handler_test').payload = #{encode_js(payload)};"
    )
  end

  def check_permissions(socket, _sender) do
    if controller(socket) == DrabTestApp.NakedController && action(socket) == :index do
      true
    else
      false
    end
  end
end
