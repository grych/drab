defmodule Drab.Live.CryptoTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.Crypto
  import Drab.Live.Crypto

  test "uuid should be uniqe" do
    # credo:disable-for-next-line
    refute uuid() == uuid()
  end

  test "encode and decode" do
    quoted =
      quote do
        z = x * y
        to_string(z)
      end

    assert quoted |> encode32() |> decode32() == quoted
    assert quoted |> encode64() |> decode64() == quoted
  end
end
