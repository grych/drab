defmodule Drab.CoreTest do
  use ExUnit.Case, ascync: true
  # doctest Drab.Core

  test "encode_js" do
    assert Drab.Core.encode_js(false) == "false"
    assert Drab.Core.encode_js(1) == "1"
    assert Drab.Core.encode_js([1,2]) == "[1,2]"
    assert Drab.Core.encode_js(%{a: 1}) == "{\"a\":1}"
  end
  
end
