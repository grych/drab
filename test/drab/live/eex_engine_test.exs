defmodule Drab.Live.EExEngineTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.EExEngine
  import Drab.Live.EExEngine

  test "last opened tag" do
    htmls = [
      {"<div><b>a</b><span><script a=\"b\" something", "script"},
      {"<div><b>a</b><span><script a=\"b\"", "script"},
      {"<div><b>a</b><span \n a=b b='c' something", "span"},
      {"<div\n><b \na=1>\na</b><span \n a=b b='c' something", "span"},
      {"<div><b>a</b\n><span \n a=b b='c' something", "span"},
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
      {"<div><b>a</b><span\na=b b='c' drab-ampere='drab_id' something", "drab_id"},
      {"<div\n><b>a</b><span drab-ampere='other'></span><b></b><span drab-ampere='drab_id' something", "drab_id"},
      {"<div><b>a</b><span drab-ampere='other'></span><b></b><span drab-ampere='drab_id' something>a", "drab_id"},
      {"<div><b>a</b><span drab-ampere='other'></span><b></b><span\ndrab-ampere='drab_id' something>a", "drab_id"},
      {"<div><b>a</b><span drab-ampere='other'></span><b></b><span\ndrab-ampere='drab_id'>a", "drab_id"},
      {"<div><b\n>a</b><span drab-ampere='other'></span><b></b><span something", nil},
      {"<div><b>a</b\n><span drab-ampere='other'></span><b></b><span something>", nil},
      {"<div><b>a</b><span \n a=b b='c' something", nil},
      {"<div><b>a</b><span \n a=b b='c' something> a ", nil}
    ]
    for {html, drab_id} <- htmls do
      assert drab_id(html, "span") == drab_id
    end
  end

  test "extract attribute from html" do
    htmls = [
      {"<div><b>a</b><span><script\n a=\"b\" something=", "something"},
      {"<div><b\n>a</b><span><script a=\"b\" something='", "something"},
      {"<div><b>a</b><span><script a=\"b\" something = 'abc ", "something"},
      {"<div><b>a</b><span\n><script a=\"b\" something\n=\n\"\nabc\n", "something"},
      {"<div><b>a</b><span><script a=\"b\" something=\"", "something"},
      {"<div><b>a</b><span><script\n a=\"b\" something = \"abc ", "something"},
      {"<div><b>a</b\n><span><script\n a=\"b\" something\n=\n\"\nabc\n", "something"},
      {"<div><b>a</b><span something=", "something"},
      {"<div><b>a</b><span something = '", "something"},
      {"<div\n><b>a</b><script a=b something", nil},
      {"<div><b>a</b\n><script else=\"else\" \nsomething   ", nil},
      {"<div><b>a\n</b><script", nil},
      {"<div><b>a</b><span a=\"b\" @something=", "@something"},
      {"<div><b>a</b><span @something.else = '", "@something.else"},
    ]
    for {html, attribute} <- htmls do
      assert attribute == find_attr_in_html(html)
    end
  end

  # test "attribute in quotes" do
  #   htmls = [
  #     {"<div><b>a</b><span><script a=\"b\" something=", false},
  #     {"<div><b>a</b><span><script a=\"b\" something='", true},
  #     {"<div><b>a</b><span><script a=\"b\" something = 'abc ", true},
  #     {"<div><b>a</b><span><script a=\"b\" something\n=\n\"\nabc\n", true},
  #     {"<div><b>a</b><span><script a=\"b\" something=\"", true},
  #     {"<div><b>a</b><span><script a=\"b\" something = \"abc ", true},
  #     {"<div><b>a</b><span><script a=\"b\" something\n=\n\"\nabc\n", true},
  #     {"<div><b>a</b><span something=", false},
  #     {"<div><b>a</b><span something = '", true},
  #     {"<div><b>a</b><script a=b something", nil},
  #     {"<div><b>a</b><script else=\"else\" \nsomething   ", nil},
  #     {"<div><b>a</b><script", nil},
  #     {"<div><b>a</b><span a=\"b\" @something=", false},
  #     {"<div><b>a</b><span @something.else = '", true},
  #   ]
  #   for {html, quoted?} <- htmls do
  #     assert quoted? == attr_begins_with_quote?(html)
  #   end
  # end

  test "proper property" do
    htmls = [
      {"<div><b>a</b><span><script a=\"b\" @something=", true},
      {"<div><b>a</b><span><script a=\"b\" @something='", false},
      {"<div\n><b>a</b><span><script a=\"b\" @something = 'abc ", false},
      {"<div><b>a</b><span><script a=\"b\" @something\n=\n\"\nabc\n", false},
      {"<div\n><b>a</b><span><script a=\"b\" @something=\"", false},
      {"<div><b>a</b><span><script a=\"b\" @something = \"abc ", false},
      {"<div\n><b>a</b><span><script a=\"b\" @something\n=\n\"\nabc\n", false},
      {"<div><b>a</b><span @something=", true},
      {"<div><b\n>a</b><span @something = ", true},
      {"<div><b\n>a</b><span\n@something = ", true},
      {"<div><b>a</b><span @something = '", false},
      {"<div><b\n>a</b><script a=b @something", false},
      {"<div><b>a</b><script else=\"else\" \n@something   ", false},
      {"<div><b>a</b><script a=b something", false},
      {"<div><b>a</b><script else=\"else\" \nsomething   ", false},
      {"<div><b>a</b><script", false},
      {"<div><b>a</b><span a=\"b\" @something=", true},
      {"<div><b>a</b><span @something.else = ", true},
      {"<div><b>a</b><span @something.else = '", false}
    ]
    for {html, proper?} <- htmls do
      assert proper? == proper_property(html)
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
