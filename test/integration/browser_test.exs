defmodule DrabTestApp.BrowserTest do
  use DrabTestApp.IntegrationCase
  import Drab.Browser

  defp browser_index do
    browser_url(DrabTestApp.Endpoint, :browser)
  end

  setup do
    browser_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for a page to load
    [socket: drab_socket()]
  end

  describe "Drab.Browser" do
    test "datetime functions" do
      socket = drab_socket()
      dt = socket |> now()
      assert dt.year >= 2017
      assert is_tuple(dt.microsecond)
      offset = socket |> utc_offset()
      assert is_integer(offset)
    end

    test "user agent and languages" do
      socket = drab_socket()
      ua = user_agent(socket)
      assert is_binary(ua)
      assert String.contains?(ua, "Chrome") ## only chromedriver supported so far
      assert is_binary(language(socket))
      refute is_nil(language(socket))
      assert is_list(languages(socket))
    end
  end
end
