defmodule DrabTestApp.SharedTest do
  use DrabTestApp.IntegrationCase
  # import Drab.Core
  # import ExUnit.CaptureLog

  defp share_index do
    share_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    share_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "not defined handler" do
    @tag capture_log: true
    test "should raise" do
      assert_raise RuntimeError,
        ~r/must be declared as public in the commander/s,
        fn -> click_and_wait("not-defined-handler-button") end
    end
  end

  describe "not declared controller" do
    @tag capture_log: true
    test "should raise" do
      assert_raise RuntimeError,
        ~r/is not declared in DrabTestApp.ShareController/s,
        fn -> click_and_wait("not-defined-controller-button") end
    end
  end

  describe "clicking global button" do
    test "shold update simple text" do
      assert all_elements?("spaceholder1", &visible_text/1, "Nothing")
      click_and_wait("global-button")
      assert all_elements?("spaceholder1", &visible_text/1, "changed globally")
    end

    test "should update all the amperes" do
      assert all_elements?("spaceolder2", &visible_text/1, "assigned in controller")

      assert all_elements?(
               "spaceholder2",
               &css_property(&1, "background-color"),
               "rgba(221, 221, 221, 1)"
             )

      assert all_elements?("spaceholder2", &css_property(&1, "color"), "rgba(255, 34, 34, 1)")

      click_and_wait("global-button")

      assert all_elements?("spaceholder2", &visible_text/1, "set globally")

      assert all_elements?(
               "spaceholder2",
               &css_property(&1, "background-color"),
               "rgba(128, 128, 128, 1)"
             )

      assert all_elements?("spaceholder2", &css_property(&1, "color"), "rgba(255, 255, 255, 1)")
    end

    test "peek should return changed value" do
      assert all_elements?({:css, "[drab-click='peek_text']"}, &visible_text/1, "peek :text")
      click_all_peeks()

      assert all_elements?(
               {:css, "[drab-click='peek_text']"},
               &visible_text/1,
               "assigned in controller"
             )

      click_and_wait("global-button")
      click_all_peeks()
      assert all_elements?({:css, "[drab-click='peek_text']"}, &visible_text/1, "set globally")
    end
  end

  describe "clicking button in shared module" do
    test "should update the corresponding text only" do
      assert all_elements?("spaceholder1", &visible_text/1, "Nothing")
      click_and_wait("shared1-button")
      refute all_elements?("spaceholder1", &visible_text/1, "changed globally")
      assert visible_text(find_element(:id, "spaceholder10")) == "Nothing"
      assert visible_text(find_element(:id, "spaceholder11")) == "changed"
      assert visible_text(find_element(:id, "spaceholder12")) == "Nothing"

      click_and_wait("shared12-button")
      assert visible_text(find_element(:id, "spaceholder10")) == "Nothing"
      assert visible_text(find_element(:id, "spaceholder11")) == "changed"
      assert visible_text(find_element(:id, "spaceholder12")) == "changed"
    end

    test "should update all the amperes" do
      click_and_wait("shared1-button")
      refute all_elements?("spaceholder2", &visible_text/1, "assigned in controller")
      assert visible_text(find_element(:id, "spaceholder20")) == "assigned in controller"

      assert css_property(find_element(:id, "spaceholder20"), "background-color") ==
               "rgba(221, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder20"), "color") == "rgba(255, 34, 34, 1)"

      assert visible_text(find_element(:id, "spaceholder21")) ==
               "changed in shared commander, one."

      assert css_property(find_element(:id, "spaceholder21"), "background-color") ==
               "rgba(119, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder21"), "color") == "rgba(153, 0, 0, 1)"
      assert visible_text(find_element(:id, "spaceholder22")) == "assigned in controller"

      assert css_property(find_element(:id, "spaceholder22"), "background-color") ==
               "rgba(221, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder22"), "color") == "rgba(255, 34, 34, 1)"

      click_and_wait("shared12-button")
      assert visible_text(find_element(:id, "spaceholder20")) == "assigned in controller"

      assert css_property(find_element(:id, "spaceholder20"), "background-color") ==
               "rgba(221, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder20"), "color") == "rgba(255, 34, 34, 1)"

      assert visible_text(find_element(:id, "spaceholder21")) ==
               "changed in shared commander, one."

      assert css_property(find_element(:id, "spaceholder21"), "background-color") ==
               "rgba(119, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder21"), "color") == "rgba(153, 0, 0, 1)"

      assert visible_text(find_element(:id, "spaceholder22")) ==
               "changed in shared commander, two"

      assert css_property(find_element(:id, "spaceholder22"), "background-color") ==
               "rgba(119, 221, 221, 1)"

      assert css_property(find_element(:id, "spaceholder22"), "color") == "rgba(153, 0, 0, 1)"

      click_and_wait("global-button")
      assert all_elements?("spaceholder2", &visible_text/1, "set globally")

      assert all_elements?(
               "spaceholder2",
               &css_property(&1, "background-color"),
               "rgba(128, 128, 128, 1)"
             )

      assert all_elements?("spaceholder2", &css_property(&1, "color"), "rgba(255, 255, 255, 1)")
    end

    test "peek should return changed value" do
      click_and_wait("shared1-button")
      click_and_wait("peek0")
      click_and_wait("peek1")
      click_and_wait("peek12")
      assert visible_text(find_element(:id, "peek0")) == "assigned in controller"
      assert visible_text(find_element(:id, "peek1")) == "changed in shared commander, one."
      assert visible_text(find_element(:id, "peek12")) == "assigned in controller"

      click_and_wait("shared12-button")
      click_and_wait("peek0")
      click_and_wait("peek1")
      click_and_wait("peek12")
      assert visible_text(find_element(:id, "peek0")) == "assigned in controller"
      assert visible_text(find_element(:id, "peek1")) == "changed in shared commander, one."
      assert visible_text(find_element(:id, "peek12")) == "changed in shared commander, two"

      click_and_wait("global-button")
      click_all_peeks()
      assert all_elements?({:css, "[drab-click='peek_text']"}, &visible_text/1, "set globally")
    end
  end

  describe "callbacks" do
    test "onload and onconnect" do
      assert visible_text(find_element(:id, "shared1_onload")) == "set in onload"
      assert visible_text(find_element(:id, "shared1_onconnect")) == "set in onconnect"
    end

    test "before and after" do
      click_and_wait("shared1-button")
      assert visible_text(find_element(:id, "shared11_before_handler")) == "set in before_handler"
      assert visible_text(find_element(:id, "shared11_after_handler")) == "set in after_handler"
      refute visible_text(find_element(:id, "shared12_before_handler")) == "set in before_handler"
      refute visible_text(find_element(:id, "shared12_after_handler")) == "set in after_handler"

      click_and_wait("shared12-button")
      assert visible_text(find_element(:id, "shared11_before_handler")) == "set in before_handler"
      assert visible_text(find_element(:id, "shared11_after_handler")) == "set in after_handler"
      assert visible_text(find_element(:id, "shared12_before_handler")) == "set in before_handler"
      assert visible_text(find_element(:id, "shared12_after_handler")) == "set in after_handler"
    end
  end

  defp click_all_peeks() do
    click_and_wait("peek0")
    click_and_wait("peek1")
    click_and_wait("peek12")
    click_and_wait("peek2")
    click_and_wait("peek02")
  end

  defp all_elements?({type, x}, function, value) do
    find_all_elements(type, x)
    |> Enum.map(function)
    |> Enum.all?(&(&1 == value))
  end

  defp all_elements?(class, function, value) do
    all_elements?({:class, class}, function, value)
  end
end
