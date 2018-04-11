defmodule DrabTestApp.Broadcast2Test do
  use DrabTestApp.IntegrationCase

  defp broadcast2_index do
    broadcast2_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    broadcast2_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator")
  end

  setup do
    wait_for_drab()
    [socket: drab_socket()]
  end

  test "same controller" do
    change_to_secondary_session()
    wait_for_drab()

    change_to_default_session()
    click_and_wait("broadcast2_button")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to same controller"

    change_to_secondary_session()
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to same controller"
  end
end
