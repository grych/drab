defmodule DrabTestApp.Broadcast5Test do
  use DrabTestApp.IntegrationCase

  defp broadcast1_index do
    broadcast1_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast2_index do
    broadcast2_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast2_different_url do
    different_url_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast3_index do
    broadcast3_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast4_index do
    broadcast4_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast5_index do
    broadcast5_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    find_element(:id, "page_loaded_indicator")
  end


  test "all browsers, except me" do
    change_to_secondary_session("1")
    broadcast1_index() |> navigate_to()
    wait_for_drab()

    change_to_secondary_session("2")
    broadcast2_index() |> navigate_to()
    wait_for_drab()

    change_to_secondary_session("21")
    broadcast2_different_url() |> navigate_to()
    wait_for_drab()

    change_to_secondary_session("3")
    broadcast3_index() |> navigate_to()
    wait_for_drab()

    change_to_secondary_session("4")
    broadcast4_index() |> navigate_to()
    wait_for_drab()

    change_to_default_session()
    broadcast5_index() |> navigate_to()
    wait_for_drab()

    click_and_wait("broadcast5_button")
    refute visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"

    change_to_secondary_session("1")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"

    change_to_secondary_session("2")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"

    change_to_secondary_session("21")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"

    change_to_secondary_session("3")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"

    change_to_secondary_session("4")
    assert visible_text(find_element(:id, "broadcast_out")) == "Broadcasted Text to the all"
  end
end
