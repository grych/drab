defmodule Drab.CoreTest do
  import Drab.Core
  
  use ExUnit.Case, ascync: true
  doctest Drab.Core, only: [same_path: 1, same_controller: 1, same_topic: 1]

  test "encode_js" do
    assert Drab.Core.encode_js(false) == "false"
    assert Drab.Core.encode_js(1) == "1"
    assert Drab.Core.encode_js([1,2]) == "[1,2]"
    assert Drab.Core.encode_js(%{a: 1}) == "{\"a\":1}"
  end
  
end
