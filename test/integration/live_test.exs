defmodule DrabTestApp.LiveTest do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  defp live_index do
    live_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    live_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for the Drab to initialize
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "simple poke and peek on global" do
      socket = drab_socket()
      poke(socket, count: 42)
      assert peek(socket, :count) == 42
    end

    test "poke onload" do
      socket = drab_socket()
      assert peek(socket, :text) == "set in the commander"
      set_onload = find_element(:id, "text_to_set_onload")
      assert visible_text(set_onload) == "set in the commander"
    end

    test "non existing peek and poke should raise" do
      socket = drab_socket()
      assert_raise ArgumentError, fn ->
        poke(socket, nonexist: 42)
      end
      assert_raise ArgumentError, fn ->
        peek(socket, :nonexits)
      end
      assert_raise ArgumentError, fn ->
        poke(socket, "partial3.html", color: "red")
      end
      assert_raise ArgumentError, fn ->
        peek(socket, "partial3.html", :color)
      end
    end

    test "change assign in main should not touch partial" do
      socket = drab_socket()
      poke socket, color: 42
      refute peek(socket, "partial1.html", :color) == 42
      assert peek(socket, :color) == 42
    end

    test "change assign in partial should not touch main" do
      socket = drab_socket()
      poke socket, "partial1.html", color: 42
      assert peek(socket, "partial1.html", :color) == 42
      refute peek(socket, :color) == 42
    end

    test "change assign in external partial should not touch main and internal one" do
      socket = drab_socket()
      poke socket, DrabTestApp.Live2View, "partial2.html", color: 42
      assert peek(socket, DrabTestApp.Live2View, "partial2.html", :color) == 42
      refute peek(socket, "partial1.html", :color) == 42
      refute peek(socket, :color) == 42
    end

    test "updating color in main should change style.backgroundColor in main, but not in partials" do
      socket = drab_socket()
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke socket, color: "red"
      assert css_property(main_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
    end

    test "updating color in partial should change style.backgroundColor in the partial only" do
      socket = drab_socket()
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke socket, "partial1.html", color: "red"
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
    end

    test "updating color in external partial should change style.backgroundColor in the partial only" do
      socket = drab_socket()
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke socket, DrabTestApp.Live2View, "partial2.html", color: "red"
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
    end

    test "updating the attribute in one partial should not affect the other" do
      socket = drab_socket()
      partial1_href = find_element(:id, "partial1_href")
      partial2_href = find_element(:id, "partial2_href")
      assert attribute_value(partial1_href, "href") == "https://tg.pl/"
      poke socket, "partial1.html", link: "https://tg.pl/drab"
      assert attribute_value(partial1_href, "href") == "https://tg.pl/drab"
      assert attribute_value(partial2_href, "href") == "https://tg.pl/"
    end

    test "script test" do
      socket = drab_socket()
      poke socket, "partial1.html", in_partial: "partial1_updated"
      test_val = Drab.Core.exec_js!(socket, "__drab_test")
      assert test_val == "partial1_updated"
    end

    test "conn should be read only" do
      socket = drab_socket()
      assert_raise ArgumentError, fn ->
        poke(socket, conn: "whatever")
      end
      assert_raise ArgumentError, fn ->
        peek(socket, :conn)
      end
    end

    test "Drab.Live.assigns should return the proper assigns list" do
      socket = drab_socket()
      assert Enum.sort(assigns(socket)) == [:color, :count, :text, :users]
      assert Enum.sort(assigns(socket, "partial1.html")) == [:color, :in_partial, :link]
      assert Enum.sort(assigns(socket, DrabTestApp.Live2View, "partial2.html")) == [:color, :in_partial, :link]
    end
  end
end
