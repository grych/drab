defmodule DrabTestApp.NakedTest do
  use DrabTestApp.IntegrationCase
  import Drab.Core

  defp naked_index do
    naked_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    naked_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for a page to load
    [socket: drab_socket()]
  end

  describe "Drab.Core in naked mode" do
    test "run_handler should set up the value of the DIV correctly" do
      socket = drab_socket()
      exec_js! socket, "Drab.run_handler('anything', 'run_handler_test', {click: 'clickety-click'});"
      assert inner_text(find_element(:id, "run_handler_test")) == "%{\"click\" => \"clickety-click\"}"
      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{"click" => "clickety-click"}
    end
  end
end
