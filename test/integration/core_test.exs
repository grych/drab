defmodule DrabTestApp.CoreTest do
  use DrabTestApp.IntegrationCase

  defp core_index do
    core_url(DrabTestApp.Endpoint, :core)
  end

  setup do
    core_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for a page to load
    :ok
  end

  test "execjs and broadcast" do
    # test execjs and broadcastjs
    standard_click_and_get_test("core1")
    standard_click_and_get_test("core2")
  end

  test "session" do
    # this session value should be visible
    session_value = find_element(:id, "test_session_value1")
    assert visible_text(session_value) == "test session value 1"

    # and this one not, as it is not listed in `access_session`
    session_value = find_element(:id, "test_session_value2")
    assert visible_text(session_value) == ""
  end

  test "store" do
    # test if the store is set up correctly
    click_and_wait("set_store_button")
    click_and_wait("get_store_button")

    store_value = find_element(:id, "store1_out")
    assert visible_text(store_value) == "test store value"
  end

  ### TODO: find out how to make persistent store test (not working in chromedriver by default, use profiles?)

end
