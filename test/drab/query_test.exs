defmodule Drab.QueryTest do
  use ExUnit.Case, ascync: true
  # doctest Drab.Query

  test "select/2 should raise on non-existing method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.select(nil, non_existing: :some_arguments, from: "")
    end
  end

  test "select/3 should raise on non-existing method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.select(nil, :non_existing, from: "")
    end
  end

  test "update/3 should raise on non-existing method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.update(nil, :non_existing, set: :something, on: "")
    end
  end

  test "update/2 should raise on non-existing method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.update(nil, non_existing: :arguments, set: :something, on: "")
    end
  end

  test "insert/2 should raise on non-existing insert method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.insert(nil, no_class: "pierwsza A", into: "")
    end
  end

  test "insert/3 should raise on non-existing insert method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.insert(nil, "some html", something_else_than_after_of_before: "")
    end
  end

  test "delete/2 should raise on non-existing delete method" do
    assert_raise ArgumentError, ~r"Drab does not recognize your query", fn ->
      Drab.Query.delete(nil, somewhere_wrong: "", from: "")
    end
  end

end
