defmodule DrabTestApp.QueryTest do
  # import Drab.Core
  import Drab.Query
  use DrabTestApp.IntegrationCase

  defp query_index do
    query_url(DrabTestApp.Endpoint, :query)
  end

  setup do
    query_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for the Drab to initialize
    [socket: drab_socket()]
  end

  describe "Drab.Query select" do

    test "basic select/3", context do
      socket = context[:socket]
      text = socket |> select(:text, from: "#select1_div")
      assert text == "text in select1_div"

      texts = socket |> select(:texts, from: ".select_div")
      assert texts == %{"__undefined_0" => "text in select3_div",
                        "select1_div" => "text in select1_div",
                        "select2_div" => "text in select2_div"}

      html = socket |> select(:html, from: "#select1_div")
      assert html == "<b>text in select1_div</b>"

      htmls = socket |> select(:htmls, from: ".select_div")
      assert htmls == %{"__undefined_0" => "text in select3_div",
                        "select1_div" => "<b>text in select1_div</b>",
                        "select2_div" => "text in select2_div"}

      val = socket |> select(:val, from: ".select_input") # should return first value
      assert val == "select1 value"

      vals = socket |> select(:vals, from: ".select_input")
      assert vals == %{"__undefined_0" => "select3 value",
                        "select1_input" => "select1 value",
                        "select2_input" => "select2 value"}
    end

    test "extended select/3 which returns an integer" do
      socket = drab_socket()
      selector = "#select1_div"
      tests = [{:width, :widths}, {:height, :heights}, 
               {:innerWidth, :innerWidths}, {:innerHeight, :innerHeights}, 
               {:scrollTop, :scrollTops}, {:scrollLeft, :scrollLefts}]
      for {singular, plural} <- tests do
        # this test does not check the exact return of jquery method
        ret = socket |> select(singular, from: selector)
        assert is_integer(ret)

        nohashed = nohash(selector)
        %{^nohashed => ret} = socket |> select(plural, from: selector)
        assert is_integer(ret)

        ret = socket |> select(singular, from: "#nonexiting")
        assert is_nil(ret)

        ret = socket |> select(plural, from: "#nonexiting")
        assert ret == %{}
      end
    end

    test "extended select/3 which returns a map" do
      socket = drab_socket()
      selector = "#select1_div"
      tests = [{:position, :positions}, {:offset, :offsets}]
      for {singular, plural} <- tests do
        ret = socket |> select(singular, from: selector)
        assert is_map(ret)
        assert Map.keys(ret) == ["left", "top"]

        nohashed = nohash(selector)
        %{^nohashed => ret} = socket |> select(plural, from: selector)
        assert is_map(ret)
        assert Map.keys(ret) == ["left", "top"]

        ret = socket |> select(singular, from: "#nonexiting")
        assert is_nil(ret)

        ret = socket |> select(plural, from: "#nonexiting")
        assert ret == %{}
      end
    end

    test "select/2" do
      socket = drab_socket()

      ret = socket |> select(attr: :test_attr, from: "#select1_div")
      assert ret == "attr1"
      socket |> update(attr: :test_attr, set: "attr1_updated", on: "#select1_div")
      ret = socket |> select(attr: :test_attr, from: "#select1_div")
      assert ret == "attr1_updated"
      ret = socket |> select(attrs: :test_attr, from: "#select1_div")
      assert ret == %{"select1_div" => "attr1_updated"}

      # property is not an attribute!
      ret = socket |> select(prop: :test_prop, from: "#select2_div")
      assert ret == nil
      socket |> update(prop: :test_prop, set: "prop2_updated", on: "#select2_div")  
      ret = socket |> select(prop: :test_prop, from: "#select2_div")
      assert ret == "prop2_updated"
      ret = socket |> select(props: :test_prop, from: "#select2_div")
      assert ret == %{"select2_div" => "prop2_updated"}
    end

    test "select/2 continued" do
      socket = drab_socket()

      ret = socket |> select(css: "font-size", from: "#select1_div")
      assert Regex.match?(~r/\d+px/, ret)

      %{"select1_div" => ret} = socket |> select(csses: "font-size", from: "#select1_div")
      assert Regex.match?(~r/\d+px/, ret)

      ret = socket |> select(data: :test, from: "#select1_div")
      assert ret == "test_data"
      ret = socket |> select(data: :test, from: "#select2_div")
      assert ret == nil

      %{"select1_div" => ret} = socket |> select(datas: :test, from: "#select1_div")
      assert ret == "test_data"
      ret = socket |> select(datas: :test, from: "#select2_div")
      assert ret == %{}
    end

    test "select all" do
      socket = drab_socket()
      selector = "#select1_div"

      nohashed = nohash(selector)

      ret = socket |> select(:all, from: selector)
      assert is_map(ret)
      assert Map.keys(ret) == [nohashed]

      %{^nohashed => ret} = socket |> select(:all, from: selector)
      assert is_map(ret)

      ret = socket |> select(:all, from: "#nonexiting")
      assert ret == %{}
    end

    test "wrong jQuery method" do
      socket = drab_socket()
      assert_raise ArgumentError, fn ->
        socket |> select(:wrong, from: "anything")
      end
    end
  end
end
