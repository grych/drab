defmodule Drab.Live.EExEngineTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.EExEngine
  import Drab.Live.EExEngine


  test "trailing text" do
    lines = [
      {"<tag attr=", ""},
      {"<tag attr= '", ""},
      {"<tag attr =\n \"", ""},
      {"<tag attr=before", "before"},
      {"<tag attr=  before", "before"},
      {"<tag attr = \nbefore", "before"},
      {"<tag attr\n=\t\n   before", "before"},
      {"<tag attr='before'", "before"},
      {"<tag attr=  '  before '", "  before "},
      {"<tag attr=\n\" before \"", " before "},
      {"<tag attr='\nbefore'", "\nbefore"}
    ]
    for {line, attr} <- lines do
      assert find_prefix_in_line(line) == attr 
    end
  end

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

end
