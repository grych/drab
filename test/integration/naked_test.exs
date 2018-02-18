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
      exec_js!(socket, "Drab.exec_elixir('run_handler_test', {argument: 'clickety-click'});")

      assert inner_text(find_element(:id, "run_handler_test")) == "%{\"argument\" => \"clickety-click\"}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "argument" => "clickety-click"
             }
    end
  end

  describe "Handler function in the shared commander" do
    test "exec_elixir should set up the value of the DIV correctly", fixture do
      socket = fixture.socket

      exec_js!(
        socket,
        "Drab.exec_elixir('DrabTestApp.LoneCommander.lone_handler', {click: ['click one']});"
      )

      assert inner_text(find_element(:id, "run_handler_test")) == "%{\"click\" => [\"click one\"]}"

      assert exec_js!(socket, "document.getElementById('run_handler_test').payload") == %{
               "click" => ["click one"]
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
      assert drab_attribute("outside_drab_commander") == "click:run_handler_test"
    end

    @tag capture_log: true
    test "non public handler should raise", fixture do
      log = log_for_handler(fixture.socket, "DrabTestApp.LoneCommander.non_public_handler")

      assert String.contains?(
               log,
               "handler Elixir.DrabTestApp.LoneCommander.non_public_handler is not public"
             )
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

  describe "optional argument" do
    test "should be correctly parsed" do
      assert drab_attribute("handler_with_null_param") == "click:run_handler_test()"
      assert drab_attribute("handler_with_param_1") == "click:run_handler_test('text:text')"

      assert drab_attribute("handler_with_param_2") == "click:run_handler_test(Drab.toLocaleString())"

      assert drab_attribute("handler_with_param_3") == "click:run_handler_test({one: 1, two: 2})"

      assert drab_attribute("handler_with_param_4") == "click:My.Commander.run_handler_test({one: 1, two: 2})"

      assert drab_attribute("handler_with_param_5") == "click#debounce(500):run_handler_test({one: 1, two: 2})"

      assert drab_attribute("handler_with_param_6") ==
               "click#debounce(500):My.Commander.run_handler_test({one: 1, two: 2})"

      assert drab_attribute("handler_with_param_7") ==
               "click:My.Commander.run_handler_test({one: 1, two: 2}) keyup#debounce(500):My.Commander.run_handler_test({one: 1, two: 2})"

      assert drab_attribute("shared_handler_with_null_param") == "click:DrabTestApp.LoneCommander.lone_handler()"

      assert drab_attribute("shared_handler_with_param_1") ==
               "click:DrabTestApp.LoneCommander.lone_handler('text:text')"

      assert drab_attribute("shared_handler_with_param_2") == "click:DrabTestApp.LoneCommander.lone_handler(42)"

      assert drab_attribute("shared_handler_with_param_3") ==
               "click:DrabTestApp.LoneCommander.lone_handler(Drab.toLocaleString())"
    end

    test "should run handler/3 in case there is an additional argument" do
      assert inner_text(find_element(:id, "run_handler_test")) == ""

      click_and_wait("handler_with_null_param")
      assert inner_text(find_element(:id, "run_handler_test")) |> String.contains?(":params")

      click_and_wait("handler_with_param_1")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text"

      click_and_wait("handler_with_param_2")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: [object Object]"

      click_and_wait("shared_handler_with_null_param")
      assert inner_text(find_element(:id, "run_handler_test")) |> String.contains?(":params")

      click_and_wait("shared_handler_with_param_1")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text"

      click_and_wait("shared_handler_with_param_2")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: 42"

      click_and_wait("shared_handler_with_param_3")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: [object Object]"
    end

    test "set with drab-argument attribute should be correctly parsed" do
      assert drab_attribute("handler_under_div_with_null_param") == "click:run_handler_test('text:text.(text)')"

      assert drab_attribute("handler_under_div_without_param") == "click:run_handler_test('text:text.(text)')"

      assert drab_attribute("handler_under_div_with_some_param") == "click:run_handler_test(43)"
    end

    test "set with drab-argument should be correctly executed" do
      click_and_wait("handler_under_div_with_null_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text.(text)"

      click_and_wait("handler_under_div_with_some_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: 43"

      click_and_wait("handler_under_div_without_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text.(text)"

      click_and_wait("shared_handler_under_div_with_null_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text.(text)"

      click_and_wait("shared_handler_under_div_with_some_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: 43"

      click_and_wait("shared_handler_under_div_without_param")
      assert inner_text(find_element(:id, "run_handler_test")) == "with argument: text:text.(text)"
    end
  end

  defp log_for_handler(socket, handler) do
    capture_log(fn ->
      exec_js!(
        socket,
        "Drab.exec_elixir('#{handler}', {lone: ['lone one']});"
      )

      # wait for a log to appear
      Process.sleep(500)
    end)
  end

  defp drab_attribute(node_id) do
    button = find_element(:id, node_id)
    String.trim(attribute_value(button, "drab"))
  end
end
