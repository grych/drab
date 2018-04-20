defmodule DrabTestApp.Broadcast4Test do
  use DrabTestApp.IntegrationCase

  defp broadcast3_index do
    broadcast3_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast4_index do
    broadcast4_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    find_element(:id, "page_loaded_indicator")
  end

  test "different controller, same topic" do
    change_to_secondary_session()
    broadcast4_index() |> navigate_to()
    wait_for_drab()

    change_to_default_session()
    broadcast3_index() |> navigate_to()
    wait_for_drab()
    click_and_wait("broadcast3_button")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the topic"

    change_to_secondary_session()
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the topic"
  end
end
