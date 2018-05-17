defmodule DrabTestApp.LiveTest do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  defp live_index do
    live_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    live_index() |> navigate_to()
    # wait for the Drab to initialize
    Process.sleep(100)
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Live" do
    test "simple poke and peek on global", fixture do
      poke(fixture.socket, count: 42)
      assert peek(fixture.socket, :count) == 42
    end

    test "poke onload", fixture do
      assert peek(fixture.socket, :text) == "set in the commander"
      set_onload = find_element(:id, "text_to_set_onload")
      assert visible_text(set_onload) == "set in the commander"
    end

    test "non existing peek and poke should raise", fixture do
      assert_raise ArgumentError, fn ->
        poke(fixture.socket, nonexist: 42)
      end

      assert_raise ArgumentError, fn ->
        peek(fixture.socket, :nonexits)
      end

      assert_raise ArgumentError, fn ->
        poke(fixture.socket, "partial3.html", color: "red")
      end

      assert_raise ArgumentError, fn ->
        peek(fixture.socket, "partial3.html", :color)
      end
    end

    test "change assign in main should not touch partial", fixture do
      poke(fixture.socket, color: 42)
      refute peek(fixture.socket, "partial1.html", :color) == 42
      assert peek(fixture.socket, :color) == 42
    end

    test "change assign in partial should not touch main", fixture do
      poke(fixture.socket, "partial1.html", color: 42)
      assert peek(fixture.socket, "partial1.html", :color) == 42
      refute peek(fixture.socket, :color) == 42
    end

    test "change assign in external partial should not touch main and internal one", fixture do
      poke(fixture.socket, DrabTestApp.Live2View, "partial2.html", color: 42)
      assert peek(fixture.socket, DrabTestApp.Live2View, "partial2.html", :color) == 42
      refute peek(fixture.socket, "partial1.html", :color) == 42
      refute peek(fixture.socket, :color) == 42
    end

    test "updating color in main should change style.backgroundColor in main, but not in partials",
         fixture do
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke(fixture.socket, color: "red")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
    end

    test "updating color in partial should change style.backgroundColor in the partial only",
         fixture do
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke(fixture.socket, "partial1.html", color: "red")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
    end

    test "updating color in external partial should change style.backgroundColor in the partial only",
         fixture do
      main_color = find_element(:id, "color_main")
      partial1_color = find_element(:id, "partial1_color")
      partial2_color = find_element(:id, "partial2_color")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 204, 102, 1)"
      poke(fixture.socket, DrabTestApp.Live2View, "partial2.html", color: "red")
      assert css_property(main_color, "backgroundColor") == "rgba(255, 255, 255, 1)"
      assert css_property(partial1_color, "backgroundColor") == "rgba(230, 230, 230, 1)"
      assert css_property(partial2_color, "backgroundColor") == "rgba(255, 0, 0, 1)"
    end

    test "updating the attribute in one partial should not affect the other", fixture do
      assert attribute_value(find_element(:id, "partial1_href"), "href") == "https://tg.pl/"
      poke(fixture.socket, "partial1.html", link: "https://tg.pl/drab")
      assert attribute_value(find_element(:id, "partial1_href"), "href") == "https://tg.pl/drab"
      assert attribute_value(find_element(:id, "partial2_href"), "href") == "https://tg.pl/"
    end

    test "update in partial in a subfolder should work", fixture do
      assert peek(fixture.socket, "subfolder/subpartial.html", :text) == "text in the subpartial"
      poke(fixture.socket, "subfolder/subpartial.html", text: "UPDATED")
      assert peek(fixture.socket, DrabTestApp.LiveView, "subfolder/subpartial.html", :text) == "UPDATED"
      assert visible_text(find_element(:id, "subpartial_div")) == "UPDATED"
    end

    test "script test", fixture do
      poke(fixture.socket, "partial1.html", in_partial: "partial1_updated")
      test_val = Drab.Core.exec_js!(fixture.socket, "__drab_test")
      assert test_val == "partial1_updated"
    end

    test "conn should be read only", fixture do
      assert_raise ArgumentError, fn ->
        poke(fixture.socket, conn: "whatever")
      end

      assert_raise ArgumentError, fn ->
        peek(fixture.socket, :conn)
      end
    end

    test "Drab.Live.assigns should return the proper assigns list", fixture do
      assert Enum.sort(assigns(fixture.socket)) == [:color, :count, :text, :users]
      assert Enum.sort(assigns(fixture.socket, "partial1.html")) == [:color, :in_partial, :link]

      assert Enum.sort(assigns(fixture.socket, DrabTestApp.Live2View, "partial2.html")) == [
               :color,
               :in_partial,
               :link
             ]
    end

    test "nodrab test", fixture do
      refute Enum.member?(assigns(fixture.socket), :nodrab1)
    end

    # TODO: uncomment after moved to 1.6.0
    # test "/ marker test", fixture do
    #   refute Enum.member?(assigns(fixture.socket), :nodrab2)
    # end
  end
end
