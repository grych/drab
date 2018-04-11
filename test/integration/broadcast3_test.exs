defmodule DrabTestApp.Broadcast3Test do
  use DrabTestApp.IntegrationCase

  defp broadcast3_index do
    broadcast3_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    broadcast3_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator")
  end

  setup do
    broadcast3_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  test "same controller, same topic" do
    change_to_secondary_session()
    wait_for_drab()

    change_to_default_session()
    click_and_wait("broadcast3_button")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the topic"

    change_to_secondary_session()
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the topic"
  end
end
