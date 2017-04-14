defmodule DrabTestApp.WaiterTest do
  # import Drab.Query
  # import Drab.Waiter
  use DrabTestApp.IntegrationCase

  defp waiter_index do
    waiter_url(DrabTestApp.Endpoint, :waiter)
  end

  setup do
    waiter_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for the Drab to initialize
    [socket: drab_socket()]
  end

  defp click_start_waiter() do
    start_waiter = find_element(:id, "start_waiter_button") 
    click(start_waiter)
    Process.sleep 200
    refute element_enabled?(start_waiter)
    start_waiter
  end

  test "waiter should wait for click" do
    start_waiter = click_start_waiter()
    find_element(:css, "#waiter_wrapper button") |> click()
    Process.sleep 200
    assert visible_text(find_element(:id, "waiter_out_div")) == "button clicked"
    assert element_enabled?(start_waiter)
  end

  test "waiter should time out" do
    start_waiter = click_start_waiter()
    Process.sleep 1100
    assert visible_text(find_element(:id, "waiter_out_div")) == "timeout"
    assert element_enabled?(start_waiter)
  end

end
