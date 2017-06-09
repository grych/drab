defmodule Drab.Live.CryptoTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.Crypto
  import Drab.Live.Crypto

  test "uuid should be uniqe" do
    refute uuid() == uuid()
  end

  test "encode and decode" do
    quoted = quote do
      z = x * y
      to_string(z)
    end
    assert encode32(quoted) |> decode32() == quoted
    assert encode64(quoted) |> decode64() == quoted
  end
end
