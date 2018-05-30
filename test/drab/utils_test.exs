defmodule Drab.UtilsTest do
  use ExUnit.Case, ascync: true
  import Drab.Utils

  test "encode_value" do
    value = %{"message" => "Hello, World!"}
    encoded_value = "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkISJ9"

    assert encoded_value == encode_value(value)
    assert encoded_value == encode_value(value, encode: true)
    assert value == encode_value(value, encode: false)

    assert value == value |> encode_value(encrypt: true) |> decode_value(decrypt: true)
    assert value == value |> encode_value(encode: true, encrypt: true) |> decode_value(decrypt: true)
    assert value == value |> encode_value(encode: true, encrypt: true) |> decode_value(decode: true, decrypt: true)
    assert value == value |> encode_value(encode: false, encrypt: true) |> decode_value(decrypt: true)
    assert value == value |> encode_value(encode: false, encrypt: true) |> decode_value(decode: false, decrypt: true)
  end

  test "exctract a cookie" do
    cookies = "a=foo; message=Hello, World!; c=bar"
    encoded_cookies = "a=foo; map=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkISJ9; c=bar"

    assert "Hello, World!" == extract_cookie(cookies, "message", decode: false)
    assert %{"message" => "Hello, World!"} == extract_cookie(encoded_cookies, "map")
    assert %{"message" => "Hello, World!"} == extract_cookie(encoded_cookies, "map", decode: true)
    assert %{"message" => "Hello, World!"} == extract_cookie(encoded_cookies, "map", encrypted: true)
    assert %{"message" => "Hello, World!"} == extract_cookie(encoded_cookies, "map", decode: true, encrypted: true)
    assert "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkISJ9" == extract_cookie(encoded_cookies, "map", decode: false, encrypted: true)
    assert "" == extract_cookie(cookies, nil)
    assert "" == extract_cookie(cookies, "")
  end

  test "extract cookies maps" do
    cookies = "_ga=GA1.1.12345.54321; _gid=GA1.1.12345.54321; map1=eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0; _gat_gtag_UA_123ABC=1; cookiebar=CookieAllowed"
    expected_value =
      [
        %{key: "_ga", value: "GA1.1.12345.54321"},
        %{key: "_gid", value: "GA1.1.12345.54321"},
        %{key: "map1", value: "eyJtZXNzYWdlIjoiSGVsbG8sIFdvcmxkIDEhIn0"},
        %{key: "_gat_gtag_UA_123ABC", value: "1"},
        %{key: "cookiebar", value: "CookieAllowed"}
      ]
    assert expected_value == Drab.Utils.extract_cookies_maps(cookies)
  end

end
