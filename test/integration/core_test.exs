defmodule DrabTestApp.CoreTest do
  use DrabTestApp.IntegrationCase
  import Drab.Core

  defp core_index do
    core_url(DrabTestApp.Endpoint, :core)
  end

  setup do
    core_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for a page to load
    [socket: drab_socket()]
  end

  describe "Drab.Core" do

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

    test "return values of execjs", context do
      assert execjs(context[:socket], "2 + 2") == {:ok, 4}
      assert execjs(context[:socket], "nonexisting") == {:error, "nonexisting is not defined"}
    end

  end

  describe "Drab.Core callbacks" do
    test "before all should set the store", context do
      socket = context[:socket]
      click_and_wait("core1_button")
      
      assert get_store(socket, :set_in_before_all) == :before
    end

    test "after all should get the handler return value", context do
      click_and_wait("core1_button")

      assert get_store(context[:socket], :set_in_after_all) == 42
    end

    test "before handler which returns false should stop processing", context do
      click_and_wait("core3_button")

      assert get_store(context[:socket], :should_never_be_assigned) == nil
      assert find_element(:id, "core3_out") |> visible_text() == "" 
    end

    test "after handler `except` test 1", context do
      click_and_wait("core1_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == true
    end

    test "after handler `except` test 2", context do
      click_and_wait("core2_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == true
    end

    test "after handler `except` test 3", context do
      click_and_wait("core3_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == nil
    end

    test "onconnect should go before onload" do
      assert find_element(:id, "onconnect_counter") |> visible_text() == "1"
    end

    test "onload should go after onconnect" do
      assert find_element(:id, "onload_counter") |> visible_text() == "2"
    end
  end

  ### TODO: find out how to make persistent store test (not working in chromedriver by default, use profiles?)

end
