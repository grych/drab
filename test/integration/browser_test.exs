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
  end

  describe "Browser cookies" do
    test "simple" do
      socket = drab_socket()
      set_cookie!(socket, "my_cookie", "ciacho")
      assert cookies!(socket) == %{"my_cookie" => "ciacho"}
    end

    test "with default encoding" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", "ciacho!")
      assert cookies!(socket) == %{"my cookie" => "ciacho!"}
    end

    test "with ciphering" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", 42, encoder: Drab.Coder.Cipher)
      assert cookies!(socket, decoder: Drab.Coder.Cipher) == %{"my cookie" => 42}
    end

    test "with the same name, should return the one with longer path" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", "ciacho1")
      set_cookie!(socket, "my cookie", "ciacho2", path: "/tests/browser")
      set_cookie!(socket, "my cookie", "ciacho3", path: "/tests")
      assert cookies!(socket) == %{"my cookie" => "ciacho2"}
    end

    test "expiring" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", "ciacho1", max_age: 1)
      assert cookies!(socket) == %{"my cookie" => "ciacho1"}
      Process.sleep(1000)
      assert cookies(socket) == {:ok, %{}}
    end

    test "named cookie" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", "ciacho!")
      assert cookie!(socket, "my cookie") == "ciacho!"
    end

    test "delete cookie" do
      socket = drab_socket()
      set_cookie!(socket, "my cookie", "ciacho!")
      assert delete_cookie(socket, "my cookie")
    end
  end
  
  describe "Web Storage" do
    test ":session storage, plain" do
      socket = drab_socket()
      Drab.Browser.set_web_storage_item(socket, :session, "TEST", "42")
      assert Drab.Browser.get_web_storage_item(socket, :session, "TEST") == {:ok, "42"}
    end
    test ":session storage, with ciphering" do
      socket = drab_socket()
      data = [%{name: "John", age: 42}, %{name: "Paul", age: 20}]
      Drab.Browser.set_web_storage_item(socket, :session, "TEST", data,
        encoder: Drab.Coder.Cipher)
      assert Drab.Browser.get_web_storage_item(socket, :session, "TEST",
        decoder: Drab.Coder.Cipher) == {:ok, data}
    end
    test ":local storage, plain" do
      socket = drab_socket()
      Drab.Browser.set_web_storage_item(socket, :local, "TEST", "42")
      assert Drab.Browser.get_web_storage_item(socket, :local, "TEST") == {:ok, "42"}
    end
    test ":local storage, with ciphering" do
      socket = drab_socket()
      data = [%{name: "John", age: 42}, %{name: "Paul", age: 20}]
      Drab.Browser.set_web_storage_item(socket, :local, "TEST", data,
        encoder: Drab.Coder.Cipher)
      assert Drab.Browser.get_web_storage_item(socket, :local, "TEST",
        decoder: Drab.Coder.Cipher) == {:ok, data}
    end
    test "remove item" do
      socket = drab_socket()
      Drab.Browser.set_web_storage_item(socket, :local, "TEST", "42")
      assert Drab.Browser.remove_web_storage_item(socket, "TEST") == {:ok, nil}
    end
    test "check browser support" do
      socket = drab_socket()
      assert Drab.Browser.check_web_storage_support(socket) == {:ok, true}
    end
  end
end
