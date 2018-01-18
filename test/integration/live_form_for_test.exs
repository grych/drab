defmodule DrabTestApp.LiveFormForTest do
  import Drab.Element
  import Drab.Core
  use DrabTestApp.IntegrationCase

  defp form_for_index do
    form_for_url(DrabTestApp.Endpoint, :form_for)
  end

  setup do
    form_for_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "add item should preserve the value of the other input" do
      socket = drab_socket()
      assert query!(socket, "#drab_text", :value) == %{"#drab_text" => %{"value" => ""}}
      element = find_element(:id, "drab_text")
      fill_field(element, "Anything")
      assert query!(socket, "#drab_text", :value) == %{"#drab_text" => %{"value" => "Anything"}}
      assert exec_js!(socket, "document.querySelectorAll('li').length") == 2
      click_and_wait("add_item")
      assert query!(socket, "#drab_text", :value) == %{"#drab_text" => %{"value" => "Anything"}}
      assert exec_js!(socket, "document.querySelectorAll('li').length") == 3
    end
  end
end
