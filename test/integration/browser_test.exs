defmodule DrabTestApp.BrowserTest do
  use DrabTestApp.IntegrationCase
  import Drab.Browser

  defp browser_index do
    browser_url(DrabTestApp.Endpoint, :browser)
  end

  setup do
    browser_index() |> navigate_to()
    # wait for a page to load
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Browser" do
    test "datetime functions" do
      socket = drab_socket()
      {:ok, dt} = socket |> now()
      assert dt.year >= 2017
      assert is_tuple(dt.microsecond)
      {:ok, offset} = socket |> utc_offset()
      assert is_integer(offset)
    end

    test "datetime bang functions" do
      socket = drab_socket()
      dt = socket |> now!()
      assert dt.year >= 2017
      assert is_tuple(dt.microsecond)
      offset = socket |> utc_offset!()
      assert is_integer(offset)
    end

    test "check the current month, as it is crazy numbered in JS" do
      # TODO: could fail at the end or the begining of the month (different timezones, etc)
      socket = drab_socket()
      browser_dt = socket |> now!()
      server_dt = DateTime.utc_now()
      assert browser_dt.month == server_dt.month
    end

    test "user agent and languages" do
      socket = drab_socket()
      {:ok, ua} = user_agent(socket)
      assert is_binary(ua)
      ## only chromedriver supported so far
      assert String.contains?(ua, "Chrome")
      {:ok, language} = language(socket)
      {:ok, languages} = languages(socket)
      assert is_binary(language)
      refute is_nil(language)
      assert is_list(languages)
    end

    test "user agent and languages (bang versions)" do
      socket = drab_socket()
      ua = user_agent!(socket)
      assert is_binary(ua)
      ## only chromedriver supported so far
      assert String.contains?(ua, "Chrome")
      assert is_binary(language!(socket))
      refute is_nil(language!(socket))
      assert is_list(languages!(socket))
    end

    test "chaging the url" do
      socket = drab_socket()
      set_url!(socket, "/other/path")
      # assert String.contains?(Drab.Core.exec_js!(socket, "window.location.href"), "/other/path")
      assert Drab.Core.exec_js!(socket, "window.location.href") =~ "/other/path"
    end

    test "set cookie" do
      socket = drab_socket()

      # result example: "map=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkISJ9; expires=Sat, 02 Jun 2018 10:42:15 +0000; path=/;"
      assert {:ok, _} = set_cookie(socket, "map", %{"message" => "Hello, World!"}, path: "/", max_age: (3 * 24 * 60 * 60), encode: true)
    end

    test "retrieves raw cookies" do
      socket = drab_socket()

      #write some cookies
      assert {:ok, _} = set_cookie(socket, "map1", %{"message" => "Hello, World 1!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map2", %{"message" => "Hello, World 2!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map3", %{"message" => "Hello, World 3!"}, path: "/", encode: true)

      # Get cookies
      expected_result = "map1=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0; map2=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDIhIn0; map3=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDMhIn0"
      assert {:ok, ^expected_result} = raw_cookies(socket)
    end

    test "retrieves cookies" do
      socket = drab_socket()

      #write some cookies
      assert {:ok, _} = set_cookie(socket, "map1", %{"message" => "Hello, World 1!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map2", %{"message" => "Hello, World 2!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map3", %{"message" => "Hello, World 3!"}, path: "/", encode: true)

      # Get cookies
      expected_result = [%{key: "map1", value: "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0"}, %{key: "map2", value: "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDIhIn0"}, %{key: "map3", value: "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDMhIn0"}]
      assert {:ok, ^expected_result} = cookies(socket)
    end

    test "retrieve a cookie" do
      socket = drab_socket()

      #retrieve an non exixtent cookie
      assert "" == cookie(socket, "foo")

      #write and retrieve a cookie
      assert {:ok, _} = set_cookie(socket, "map", %{"message" => "Hello, World!"}, path: "/", max_age: (3 * 24 * 60 * 60), encode: true)
      assert %{"message" => "Hello, World!"} == cookie(socket, "map")
    end

    test "delete a cookie" do
      socket = drab_socket()

      #write three cookies
      assert {:ok, _} = set_cookie(socket, "map1", %{"message" => "Hello, World 1!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map2", %{"message" => "Hello, World 2!"}, path: "/", encode: true)
      assert {:ok, _} = set_cookie(socket, "map3", %{"message" => "Hello, World 3!"}, path: "/", encode: true)

      #delete a cookie
      assert {:ok, _} = delete_cookie(socket, "map2")
       # Check cookies
      expected_result = "map1=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0; map3=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDMhIn0"
      assert {:ok, ^expected_result} = raw_cookies(socket)
    end

  end
end
