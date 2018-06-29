defmodule DrabTestApp.LiveBroadcastingTest do
  use DrabTestApp.IntegrationCase

  defp broadcasting_index do
    broadcasting_url(DrabTestApp.Endpoint, :broadcasting)
  end

  defp wait_for_drab() do
    broadcasting_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator")
  end

  setup do
    wait_for_drab()
    [socket: drab_socket()]
  end

  test "poke should be broadcasted" do
    change_to_secondary_session()
    wait_for_drab()

    change_to_default_session()
    click_and_wait("broadcast_button")
    assert visible_text(find_element(:id, "broadcast_out")) == "broadcasted"

    change_to_secondary_session()
    assert visible_text(find_element(:id, "broadcast_out")) == "broadcasted"
  end
end
