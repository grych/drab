defmodule DrabTestApp.LiveQueryTest do
  import Drab.Live
  import Drab.Query
  use DrabTestApp.IntegrationCase

  defp live_query_index do
    live_query_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    live_query_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Modal" do
    test "poke the assign should change the jQuery text()" do
      socket = drab_socket()
      assert select(socket, :text, from: "#live_query_a") == "Drab Demo Page"
      poke(socket, link: "New value")
      assert select(socket, :text, from: "#live_query_a") == "New value"
    end

    test "poke the assign should change the attribue" do
      socket = drab_socket()
      assert select(socket, attr: :href, from: "#live_query_a") == "https://tg.pl/drab"
      poke(socket, href: "https://tg.pl")
      assert select(socket, attr: :href, from: "#live_query_a") == "https://tg.pl"
    end

    test "poke the assign should change the property" do
      socket = drab_socket()
      style = select(socket, prop: :style, from: "#live_query_a")
      assert style["backgroundColor"] == "rgb(255, 238, 204)"
      poke(socket, color: "red")
      style = select(socket, prop: :style, from: "#live_query_a")
      assert style["backgroundColor"] == "red"
    end
  end
end
