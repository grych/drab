defmodule Drab.QueryTest do
  use ExUnit.Case
  doctest Drab.Query

  test "this/1 should return drab_id" do
    dom_sender = %{ "drab_id" => "DRAB_ID"}
    assert Drab.Query.this(dom_sender) == "[drab-id=DRAB_ID]"
  end

  test "this!/1 should return id" do
    dom_sender = %{ "id" => "ID"}
    assert Drab.Query.this!(dom_sender) == "#ID"
  end

  test "this!/1 should raise when there is no ID" do
    dom_sender = %{ "drab_id" => "there is a DRAB_ID, but not actual id"}
    assert_raise RuntimeError, ~r"Try to use Drab.Query.this!/1 on DOM object without an ID:", fn -> 
      Drab.Query.this!(dom_sender)
    end
  end
end
