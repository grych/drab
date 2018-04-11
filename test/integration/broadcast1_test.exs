defmodule DrabTestApp.Broadcast1Test do
  use DrabTestApp.IntegrationCase

  defp broadcast1_index do
    broadcast1_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    broadcast1_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator")
  end

  setup do
    wait_for_drab()
    [socket: drab_socket()]
  end

  test "same url" do
    change_to_secondary_session()
    wait_for_drab()

    change_to_default_session()
    click_and_wait("broadcast1_button")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to same url"

    change_to_secondary_session()
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to same url"
  end
end
