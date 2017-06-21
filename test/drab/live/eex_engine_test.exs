defmodule Drab.Live.EExEngineTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.EExEngine
  import Drab.Live.EExEngine

  test "last opened tag" do
    htmls = [
      {"<div><b>a</b><span><script a=\"b\" something", "script"},
      {"<div><b>a</b><span><script a=\"b\"", "script"},
      {"<div><b>a</b><span \n a=b b='c' something", "span"},
      {"<div><b>a</b><script a=\"b\"", "script"},
      {"<div><script", "script"},
      {"<div", "div"},
      {"<div \n", "div"},
      {"<div   ", "div"}
    ]
    for {html, tag} <- htmls do
      assert last_opened_tag(html) == tag
    end
  end

  test "drab id" do
    htmls = [
      {"<div><b>a</b><span \n a=b b='c' drab-ampere='drab_id' something>", "drab_id"},
      {"<div><b>a</b><span \n a=b b='c' drab-ampere='drab_id' something", "drab_id"},
      {"<div><b>a</b><span \n a=b b='c' something", nil},
    ]
    for {html, drab_id} <- htmls do
      assert drab_id(html, "span") == drab_id
    end
  end

  test "extract attribute from html" do
    htmls = [
      {"<div><b>a</b><span><script a=\"b\" something=", "something"},
      {"<div><b>a</b><span><script a=\"b\" something='", "something"},
      {"<div><b>a</b><span><script a=\"b\" something = 'abc ", "something"},
      {"<div><b>a</b><span><script a=\"b\" something\n=\n\"\nabc\n", "something"},
      {"<div><b>a</b><span><script a=\"b\" something=\"", "something"},
      {"<div><b>a</b><span><script a=\"b\" something = \"abc ", "something"},
      {"<div><b>a</b><span><script a=\"b\" something\n=\n\"\nabc\n", "something"},
      {"<div><b>a</b><span something=", "something"},
      {"<div><b>a</b><span something = '", "something"},
      {"<div><b>a</b><script something", nil},
      {"<div><b>a</b><script", nil}
    ]
    for {html, attribute} <- htmls do
      assert attribute == find_attr_in_html(html)
    end
  end

  test "attributes from shadow" do
    shadow = {"button",
      [{"class",
        "btn {{{{@drab-ampere:ugezdsnzygi3tknq@drab-expr-hash:geytgmzvhazdsoa}}}}"}],
      ["\n  Other button  \n"]}
    assert attributes_from_shadow(shadow) == [{"class",
      "btn {{{{@drab-ampere:ugezdsnzygi3tknq@drab-expr-hash:geytgmzvhazdsoa}}}}"}]
  end

  test "extract expression hashes and ampere id from pattern" do
    pattern = "begin {{{{@drab-ampere:ugm2dcmjvgyza@drab-expr-hash:g4ztsnbsha4to}}}}
      {{{{@drab-ampere:ugm2dcmjvgyza@drab-expr-hash:geytmmrsgi2dona}}}} rest"
    assert expression_hashes_from_pattern(pattern) == ["g4ztsnbsha4to", "geytmmrsgi2dona"]
    assert ampere_from_pattern(pattern) == "ugm2dcmjvgyza"
  end

end
