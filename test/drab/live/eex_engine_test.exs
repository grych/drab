defmodule Drab.Live.EExEngineTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Live.EExEngine
  import Drab.Live.EExEngine

  test "extract attribute from line" do
    lines = [
      {"<tag attr=", "attr"},
      {"<tag attr='", "attr"},
      {"<tag attr=\"", "attr"},
      {"<tag attr=begin", "attr"},
      {"<tag attr='begin ", "attr"},
      {"<tag attr=\"begin ", "attr"},
      {"<tag attr = ", "attr"},
      {"<tag attr = '", "attr"},
      {"<tag attr = \"", "attr"},
      {"<tag a = '' attr \n= ", "attr"},
      {"<tag b = b attr \n= '", "attr"},
      {"<tag c = \"\" attr \n= \"", "attr"},
      {"<tag attr \n=\n ", "attr"},
      {"<tag attr \n=\n '", "attr"},
      {"<tag attr \n=\n \"", "attr"},
      {"<tag attr \t=\t ", "attr"},
      {"<tag attr \t=\t '", "attr"},
      {"<tag attr \t=\t \"", "attr"},
      {"attr=", "attr"},
      {"attr='", "attr"},
      {"attr=\"", "attr"},
      {"attr \n = \n ", "attr"},
      {"attr \n = \n '", "attr"},
      {"attr \n = \n\"", "attr"}
    ]
    for {line, attr} <- lines do
      assert find_attr_in_line(line) == attr 
    end
  end

  test "non-compilable tag" do
    wrong = [
      "<tag",
      "<tag ",
      "<tag \n",
      "<tag \n\r",
      "<tag attr=value ",
      "<tag attr = value ",
      "<tag attr\n=\rvalue ",
      "<tag \nattr=\"value\" ",
      "<tag\n attr = \"value\" ",
      "<tag \tattr\n=\r\"value\" ",
      "<tag attr='value' ",
      "<tag attr = 'value' ",
      "<tag attr\n=\r'value' ",
      " attr=value ",
      "\n attr = value ",
      "\t attr\n=\rvalue ",
      " attr=\"value\" ",
      "attr = \"value\" ",
      "attr\n=\r\"value\" ",
      " attr='value' ",
      "attr = 'value' ",
      " attr\n=\r'value' "
    ]
    for line <- wrong do
      assert_raise CompileError, fn -> find_attr_in_line(line) end
    end
  end

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

end
