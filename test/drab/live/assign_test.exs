defmodule Drab.Live.AssignTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.Assign
  import Drab.Live.Assign

  setup do
    conn_example = %Plug.Conn{
      adapter: {Plug.Adapters.Cowboy.Conn, nil},
      assigns: %{
        class1: "btn",
        class2: "btn-primary",
        color: "#10ffff",
        count: 42,
        full_class: "",
        hidden: false,
        in_partial: "in partial before",
        label: "default",
        layout: {DrabTestApp.LayoutView, "app.html"},
        link: "https://tg.pl/drab",
        list: 'abc',
        map: %{a: 1, b: 2},
        text: "set in the controller",
        url: "elixirforum.com",
        user: "Zofia",
        users: ["Zdzisław", "Zofia", "Hendryk", "Stefan"],
        width: nil
      },
      before_send: [fn x -> x end],
      body_params: %{},
      cookies: %{
        "_cmsv1_key" =>
          "SFMyNTY.g3QAAAABbQAAAAtfY3NyZl90b2tlbm0AAAAYaE9pakRYN1JTQm91Y1U3TC9CbklrQT09.sz1tDgl2ZQysJRR9qD0bpCytO3m7OZQ35qYtvvLp_y4",
        "_drab_poc_key" =>
          "SFMyNTY.g3QAAAADbQAAAAxjb3VudHJ5X2NvZGVkAANuaWxtAAAACWRyYWJfdGVzdG0AAAA4dGVzdCBzdHJpbmcgZnJvbSB0aGUgUGx1ZyBTZXNzaW9uLCBzZXQgaW4gdGhlIENvbnRyb2xsZXJtAAAABHRlc3RtAAAAGnRoaXMgd2FzIHNldCBpbiBDb250cm9sbGVy.bMfYNNJibdLUfX4SjZciKmySbpZSyKxyapwEonzoI58"
      },
      halted: false,
      host: "localhost",
      method: "GET",
      owner: "aa",
      params: %{},
      path_info: ["tests", "live", "mini"],
      path_params: %{},
      peer: {{127, 0, 0, 1}, 61462},
      port: 4000,
      private: %{
        DrabTestApp.Router => {[], %{}},
        :phoenix_action => :mini,
        :phoenix_controller => DrabTestApp.LiveController,
        :phoenix_endpoint => DrabTestApp.Endpoint,
        :phoenix_flash => %{},
        :phoenix_format => "html",
        :phoenix_layout => {DrabTestApp.LayoutView, :app},
        :phoenix_pipelines => [:browser],
        :phoenix_router => DrabTestApp.Router,
        :phoenix_template => "mini.html",
        :phoenix_view => DrabTestApp.LiveView,
        :plug_session => %{
          "_csrf_token" => "up49YPn8GM36fJiErkzTng==",
          "test_session_value1" => "test session value 1",
          "test_session_value2" => "test session value 2"
        },
        :plug_session_fetch => :done
      },
      query_params: %{},
      query_string: "",
      remote_ip: {127, 0, 0, 1},
      req_cookies: %{
        "_cmsv1_key" =>
          "SFMyNTY.g3QAAAABbQAAAAtfY3NyZl90b2tlbm0AAAAYaE9pakRYN1JTQm91Y1U3TC9CbklrQT09.sz1tDgl2ZQysJRR9qD0bpCytO3m7OZQ35qYtvvLp_y4",
        "_drab_poc_key" =>
          "SFMyNTY.g3QAAAADbQAAAAxjb3VudHJ5X2NvZGVkAANuaWxtAAAACWRyYWJfdGVzdG0AAAA4dGVzdCBzdHJpbmcgZnJvbSB0aGUgUGx1ZyBTZXNzaW9uLCBzZXQgaW4gdGhlIENvbnRyb2xsZXJtAAAABHRlc3RtAAAAGnRoaXMgd2FzIHNldCBpbiBDb250cm9sbGVy.bMfYNNJibdLUfX4SjZciKmySbpZSyKxyapwEonzoI58"
      },
      req_headers: [
        {"host", "localhost:4000"},
        {"connection", "keep-alive"},
        {"cache-control", "max-age=0"},
        {"upgrade-insecure-requests", "1"},
        {"user-agent",
         "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"},
        {"accept",
         "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"},
        {"referer", "http://localhost:4000/tests/live/mini"},
        {"accept-encoding", "gzip, deflate, br"},
        {"accept-language", "pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7"},
        {"cookie", ""}
      ],
      request_path: "/tests/live/mini",
      resp_body: nil,
      resp_cookies: %{},
      resp_headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"x-request-id", "2kkp5acpigh31v28i0000ct7"},
        {"x-frame-options", "SAMEORIGIN"},
        {"x-xss-protection", "1; mode=block"},
        {"x-content-type-options", "nosniff"},
        {"x-download-options", "noopen"},
        {"x-permitted-cross-domain-policies", "none"}
      ],
      scheme: :http,
      script_name: [],
      secret_key_base: "noone should know",
      state: :unset,
      status: nil
    }

    [conn_example: conn_example, empty_conn: %Plug.Conn{}]
  end

  describe "should filter out" do
    test "with default filter", fixture do
      conn = trim(fixture.conn_example)
      assert conn.private == %{phoenix_endpoint: DrabTestApp.Endpoint}
      assert conn.assigns == %{}
    end

    test "with custom filter", fixture do
      conn =
        trim(fixture.conn_example, %{
          private: %{
            phoenix_endpoint: false,
            phoenix_router: true
          },
          secret_key_base: true
        })

      assert conn.private == %{phoenix_router: DrabTestApp.Router}
      assert conn.assigns == %{}
      assert conn.secret_key_base == "noone should know"
    end

    test "with custom filter for all assigns", fixture do
      conn =
        trim(fixture.conn_example, %{
          assigns: true
        })

      assert conn.private == %{}
      refute conn.assigns == %{}
      assert Enum.count(conn.assigns) > 10
    end

    test "with custom filter for specific assigns", fixture do
      conn =
        trim(fixture.conn_example, %{
          assigns: %{
            color: true,
            text: true
          }
        })

      assert conn.private == %{}
      refute conn.assigns == %{}
      assert Enum.count(conn.assigns) == 2
      assert conn.assigns.text == "set in the controller"
    end
  end
end
