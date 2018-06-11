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

  test "encode_valueNEW" do
    value = %{"message" => "Hello, World!"}

    # TODO: YET TO BE DONE
    encoded_by_default_encoder = value

    assert value == encoded_by_default_encoder
  end

end
