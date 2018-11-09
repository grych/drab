defmodule DrabTestApp.CoreTest do
  use DrabTestApp.IntegrationCase
  import Drab.Core
  import ExUnit.CaptureLog
  import Phoenix.HTML

  defp core_index do
    core_url(DrabTestApp.Endpoint, :core)
  end

  setup do
    core_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Core" do
    # we don't want to see Drab Errors in the log
    @tag capture_log: true
    test "exec_js and broadcast_js" do
      # test execjs and broadcastjs
      standard_click_and_get_test("core1")
      standard_click_and_get_test("core2")
    end

    @tag capture_log: true
    test "multiple events on object", fixture do
      standard_click_and_get_test("core4")

      assert Drab.Core.exec_js(fixture.socket, "document.getElementById('core5_out').innerHTML") ==
               {:ok, "core5"}
    end

    @tag capture_log: true
    test "multiple events on object defined with shorthand form", fixture do
      standard_click_and_get_test("core6")

      assert Drab.Core.exec_js(fixture.socket, "document.getElementById('core7_out').innerHTML") ==
               {:ok, "core7"}
    end

    @tag capture_log: true
    test "capturing custom events", fixture do
      hijack_click = """
        var event;
        event = document.createEvent("HTMLEvents");
        event.initEvent("custom.event", true, true);

        var node = document.getElementById('core8_button');

        node.addEventListener('click', function(e) {
          e.preventDefault();
          node.dispatchEvent(event);
        });
      """

      Drab.Core.exec_js(fixture.socket, hijack_click)

      standard_click_and_get_test("core8")
    end

    @tag capture_log: true
    test "debounce", fixture do
      for t <- ["1", "2", "3"] do
        input = find_element(:id, "core#{t}_input")
        fill_field(input, "something")

        assert Drab.Core.exec_js(
                 fixture.socket,
                 "document.getElementById('input#{t}_out').innerHTML"
               ) == {:ok, ""}

        Process.sleep(600)

        assert Drab.Core.exec_js(
                 fixture.socket,
                 "document.getElementById('input#{t}_out').innerHTML"
               ) == {:ok, "input#{t}"}
      end
    end

    @tag capture_log: true
    test "session" do
      # this session value should be visible
      session_value = find_element(:id, "test_session_value1")
      assert visible_text(session_value) == "test session value 1"

      # and this one not, as it is not listed in `access_session`
      session_value = find_element(:id, "test_session_value2")
      assert visible_text(session_value) == ""
    end

    @tag capture_log: true
    test "session, set in config.exs", fixture do
      assert Drab.Core.get_session(fixture.socket, :another_session) == 42
    end

    @tag capture_log: true
    test "store" do
      # test if the store is set up correctly
      click_and_wait("set_store_button")
      click_and_wait("get_store_button")

      store_value = find_element(:id, "store1_out")
      assert visible_text(store_value) == "test store value"
    end

    @tag capture_log: true
    test "return values of exec_js", context do
      assert exec_js(context[:socket], "2 + 2") == {:ok, 4}
      assert exec_js(context[:socket], "nonexisting") == {:error, "nonexisting is not defined"}
    end

    @tag capture_log: true
    test "return values of exec_js!", context do
      assert exec_js!(context[:socket], "2 + 2") == 4

      assert_raise Drab.JSExecutionError, "nonexisting is not defined", fn ->
        exec_js!(context[:socket], "nonexisting")
      end
    end
  end

  describe "Drab.Core callbacks" do
    @tag capture_log: true
    test "before all should set the store", context do
      socket = context[:socket]
      click_and_wait("core1_button")

      assert get_store(socket, :set_in_before_all) == :before
    end

    @tag capture_log: true
    test "after all should get the handler return value", context do
      click_and_wait("core1_button")

      assert get_store(context[:socket], :set_in_after_all) == 42
    end

    @tag capture_log: true
    test "before handler which returns false should stop processing", context do
      click_and_wait("core3_button")

      assert get_store(context[:socket], :should_never_be_assigned) == nil
      assert find_element(:id, "core3_out") |> visible_text() == ""
    end

    @tag capture_log: true
    test "after handler `except` test 1", context do
      click_and_wait("core1_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == true
    end

    @tag capture_log: true
    test "after handler `except` test 2", context do
      click_and_wait("core2_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == true
    end

    @tag capture_log: true
    test "after handler `except` test 3", context do
      click_and_wait("core3_button")
      assert get_store(context[:socket], :shouldnt_be_set_in_core3) == nil
    end

    # @tag capture_log: true
    # test "onconnect should go before onload" do
    #   assert find_element(:id, "onconnect_counter") |> visible_text() == "1"
    # end

    # @tag capture_log: true
    # test "onload should go after onconnect" do
    #   assert find_element(:id, "onload_counter") |> visible_text() == "2"
    # end
  end

  describe "after disconnect" do
    @tag capture_log: true
    test "should return disconnection error" do
      log =
        capture_log(fn ->
          click_and_wait("disconnect_button")
          navigate_to(index_url(DrabTestApp.Endpoint, :index))
          Process.sleep(1000)
        end)

      assert String.contains?(log, "(Drab.ConnectionError) Disconnected")
    end
  end

  describe "disabled element" do
    @tag capture_log: true
    test "should remain disabled" do
      refute element_enabled?(find_element(:id, "disabled_button"))
    end

    @tag capture_log: true
    test "should remain disabled after close", fixture do
      broadcast_js(fixture.socket, "Drab.socket.conn.close()")
      Process.sleep(100)
      refute element_enabled?(find_element(:id, "disabled_button"))
    end
  end

  describe "enabled element" do
    @tag capture_log: true
    test "should remain enabled" do
      assert element_enabled?(find_element(:id, "core1_button"))
    end

    @tag capture_log: true
    test "should disable after close", fixture do
      broadcast_js(fixture.socket, "Drab.disconnect()")
      Process.sleep(100)
      refute element_enabled?(find_element(:id, "core1_button"))
    end
  end

  describe "enable/disable state" do
    @tag capture_log: true
    test "element should not disable after close, when drab-no-disable is set", fixture do
      broadcast_js(fixture.socket, "Drab.disconnect()")
      Process.sleep(100)
      assert element_enabled?(find_element(:id, "core9_button"))
    end

    @tag capture_log: true
    test "should be disabled after click" do
      button = find_element(:id, "core1_button")
      click(button)
      refute element_enabled?(find_element(:id, "core1_button"))
    end

    @tag capture_log: true
    test "should not be disabled after click, when drab-no-disable is set" do
      button = find_element(:id, "core9_button")
      click(button)
      assert element_enabled?(find_element(:id, "core9_button"))
    end
  end

  describe "presence" do
    @tag capture_log: true
    test "presence should be started", feature do
      assert Drab.Presence.count_connections(feature.socket) == 1

      change_to_secondary_session()
      core_index() |> navigate_to()

      # unless System.get_env("TRAVIS") do
        # for some stupid reasons it does not work with travis
      Process.sleep(1000)
      assert Drab.Presence.count_connections(feature.socket) == 2
      # end
    end

    @tag capture_log: true
    test "presence with subscribtion to some topic", feature do
      topic = same_topic("my_topic")
      Drab.Commander.subscribe(feature.socket, topic)
      assert Drab.Presence.count_connections(topic) == 1

      change_to_secondary_session()
      core_index() |> navigate_to()
      find_element(:id, "page_loaded_indicator")
      assert Drab.Presence.count_connections(topic) == 1

      socket = drab_socket()
      Drab.Commander.subscribe(socket, topic)

      unless System.get_env("TRAVIS") do
        assert Drab.Presence.count_connections(topic) == 2
      end

      Drab.Commander.unsubscribe(socket, topic)
      assert Drab.Presence.count_connections(topic) == 1
    end
  end

  describe "safe" do
    @tag capture_log: true
    test "core function should accept safe", fixture do
      dwa = 2
      assert exec_js(fixture.socket, ~E/<%= dwa %>+2/) == {:ok, 4}
      assert exec_js!(fixture.socket, ~E/<%= dwa %>+2/) == 4
      assert broadcast_js(fixture.socket, ~E/<%= dwa %>+2/) == {:ok, :broadcasted}
    end
  end
end
