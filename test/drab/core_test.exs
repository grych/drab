defmodule Drab.CoreTest do
  import Drab.Core

  use ExUnit.Case, async: true
  doctest Drab.Core, only: [same_path: 1, same_controller: 1, same_topic: 1]

  test "this/1 should return drab_id" do
    dom_sender = %{"drab_id" => "DRAB_ID"}
    assert Drab.Core.this(dom_sender) == "[drab-id=\"DRAB_ID\"]"
  end

  test "this!/1 should return id" do
    dom_sender = %{"id" => "ID"}
    assert Drab.Core.this!(dom_sender) == "#ID"
  end

  test "this!/1 should raise when there is no ID" do
    dom_sender = %{"drab_id" => "there is a DRAB_ID, but not actual id"}

    assert_raise ArgumentError,
                 ~r"Try to use Drab.Core.this!/1 on DOM object without an ID:",
                 fn ->
                   Drab.Core.this!(dom_sender)
                 end
  end

  test "encode_js" do
    assert Drab.Core.encode_js(false) == "false"
    assert Drab.Core.encode_js(1) == "1"
    assert Drab.Core.encode_js([1, 2]) == "[1,2]"
    assert Drab.Core.encode_js(%{a: 1}) == "{\"a\":1}"
  end

  test "normalize_params" do
    assert normalize_params(%{
             "_csrf" => "1234",
             "user[id]" => "42",
             "user[email]" => "test@test.com",
             "user[account][id]" => "99",
             "user[account][address][street]" => "123 Any Street"
           }) == %{
             "_csrf" => "1234",
             "user" => %{
               "account" => %{"address" => %{"street" => "123 Any Street"}, "id" => "99"},
               "email" => "test@test.com",
               "id" => "42"
             }
           }
  end
end
