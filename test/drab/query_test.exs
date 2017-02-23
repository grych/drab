defmodule Drab.QueryTest do
  use ExUnit.Case, ascync: true
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

  test "select/2 should raise on non-existing method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.select(nil, non_existing: :some_arguments, from: "")
    end
  end

  test "select/3 should raise on non-existing method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.select(nil, :non_existing, from: "")
    end
  end

  test "update/3 should raise on non-existing method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.update(nil, :non_existing, set: :something, on: "")
    end
  end

  test "update/2 should raise on non-existing method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.update(nil, non_existing: :arguments, set: :something, on: "")
    end
  end

  test "insert/2 should raise on non-existing insert method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.insert(nil, no_class: "pierwsza A", into: "")
    end
  end

  test "insert/3 should raise on non-existing insert method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.insert(nil, "some html", something_else_than_after_of_before: "")
    end
  end

  test "delete/2 should raise on non-existing delete method" do
    assert_raise RuntimeError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.delete(nil, somewhere_wrong: "", from: "")
    end
  end

end
