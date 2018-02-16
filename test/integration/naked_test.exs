defmodule DrabTestApp.NakedTest do
  use DrabTestApp.IntegrationCase
  import Drab.Core
  import ExUnit.CaptureLog

  defp naked_index do
    naked_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    naked_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Core in naked mode" do
    test "exec_elixir should set up the value of the DIV correctly", fixture do
      socket = fixture.socket
      exec_js!(socket, "Drab.exec_elixir('run_handler_test', {click: 'clickety-click'});")

      assert inner_text(find_element(:id, "run_handler_test")) ==
               "%{\"click\" => \"clickety-click\"}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "click" => "clickety-click"
             }
    end
  end

  describe "Handler function in the shared commander" do
    test "exec_elixir should set up the value of the DIV correctly", fixture do
      socket = fixture.socket

      exec_js!(
        socket,
        "Drab.exec_elixir('DrabTestApp.LoneCommander.lone_handler', {lone: ['lone one']});"
      )

      assert inner_text(find_element(:id, "run_handler_test")) == "%{\"lone\" => [\"lone one\"]}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "lone" => ["lone one"]
             }
    end

    test "button with the full path should be clickable" do
      assert inner_text(find_element(:id, "run_handler_test")) == ""
      click_and_wait("exec_lone_handler")
      assert inner_text(find_element(:id, "run_handler_test")) != ""
    end

    test "button under the drab-commander='' should be clickable" do
      assert inner_text(find_element(:id, "run_handler_test")) == ""
      click_and_wait("exec_lone_handler_2")
      assert inner_text(find_element(:id, "run_handler_test")) != ""
    end

    test "drab attribute should be unmodified for exec_lone_handler button" do
      button = find_element(:id, "exec_lone_handler")

      assert String.trim(attribute_value(button, "drab")) ==
               "click:DrabTestApp.LoneCommander.lone_handler change:DrabTestApp.LoneCommander.other_handler"
    end

    test "drab attribute should be modified for exec_lone_handler_2 button" do
      button = find_element(:id, "exec_lone_handler_2")

      assert String.trim(attribute_value(button, "drab")) ==
               "click:DrabTestApp.LoneCommander.lone_handler change:DrabTestApp.LoneCommander.other_handler"
    end

    test "drab attribute should be unmodified for outside_drab_commander button" do
      button = find_element(:id, "outside_drab_commander")

      assert String.trim(attribute_value(button, "drab")) == "click:run_handler_test"
    end

    @tag capture_log: true
    test "non public handler should raise", fixture do
      log = log_for_handler(fixture.socket, "DrabTestApp.LoneCommander.non_public_handler")
      assert String.contains?(log, "handler Elixir.DrabTestApp.LoneCommander.non_public_handler is not public")
    end

    @tag capture_log: true
    test "not existing handler should raise", fixture do
      log = log_for_handler(fixture.socket, "DrabTestApp.LoneCommander.nonexisting_handler")
      assert String.contains?(log, ":erlang.binary_to_existing_atom(\"nonexisting_handler\"")
    end

    @tag capture_log: true
    test "handler in non-drab module should raise", fixture do
      log = log_for_handler(fixture.socket, "DrabTestApp.FakeCommander.fake_handler")
      assert String.contains?(log, "Elixir.DrabTestApp.FakeCommander is not a Drab module")
    end
  end

  defp log_for_handler(socket, handler) do
    capture_log(fn ->
      exec_js!(
        socket,
        "Drab.exec_elixir('#{handler}', {lone: ['lone one']});"
      )
      Process.sleep(500) # wait for a log to appear
    end)
  end
end
