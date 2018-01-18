defmodule DrabTestApp.NakedTest do
  use DrabTestApp.IntegrationCase
  import Drab.Core

  defp naked_index do
    naked_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    naked_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Core in naked mode" do
    test "exec_elixir should set up the value of the DIV correctly" do
      socket = drab_socket()
      exec_js!(socket, "Drab.exec_elixir('run_handler_test', {click: 'clickety-click'});")

      assert inner_text(find_element(:id, "run_handler_test")) ==
               "%{\"click\" => \"clickety-click\"}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "click" => "clickety-click"
             }
    end
  end

  describe "Handler function in the other commander" do
    test "exec_elixir should set up the value of the DIV correctly" do
      socket = drab_socket()

      exec_js!(
        socket,
        "Drab.exec_elixir('DrabTestApp.LoneCommander.lone_handler', {lone: ['lone one']});"
      )

      assert inner_text(find_element(:id, "run_handler_test")) == "%{\"lone\" => [\"lone one\"]}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "lone" => ["lone one"]
             }
    end
  end
end
