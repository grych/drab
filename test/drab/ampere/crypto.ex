defmodule Drab.Ampere.CryptoTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Ampere.Crypto
  import Drab.Ampere.Crypto

  test "uuid should be uniqe" do
    refute uuid() == uuid()
  end

  test "encode and decode" do
    quoted = quote do
      z = x * y
      to_string(z)
    end
    assert encode(quoted) |> decode() == quoted
  end
end
