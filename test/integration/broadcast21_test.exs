defmodule DrabTestApp.Broadcast21Test do
  use DrabTestApp.IntegrationCase

  defp broadcast2_index do
    broadcast2_url(DrabTestApp.Endpoint, :index)
  end

  defp broadcast2_different_url do
    different_url_url(DrabTestApp.Endpoint, :index)
  end

  defp wait_for_drab() do
    find_element(:id, "page_loaded_indicator")
  end

  test "same controller, different url" do
    change_to_secondary_session()
    broadcast2_different_url() |> navigate_to()
    wait_for_drab()

    change_to_default_session()
    broadcast2_index() |> navigate_to()
    wait_for_drab()
    click_and_wait("broadcast2_button")

    assert visible_text(find_element(:id, "broadcast_out")) ==
             "Broadcasted Text to same controller"

    change_to_secondary_session()

    assert visible_text(find_element(:id, "broadcast_out")) ==
             "Broadcasted Text to same controller"
  end
end
