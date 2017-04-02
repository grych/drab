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
    :ok
  end

  describe "Drab.Query" do

    test "basic select/3" do
      socket = drab_socket()
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
      tests = [{:width, :widths}, {:height, :heights}, 
               {:innerWidth, :innerWidths}, {:innerHeight, :innerHeights}, 
               {:scrollTop, :scrollTops}, {:scrollLeft, :scrollLefts}]
      for {singular, plural} <- tests do
        socket = drab_socket()
        selector = "#select1_div"

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


# iex(9)> socket |> select(:position, from: "#select1_div")   
# %{"left" => 454, "top" => 121}
# iex(10)> socket |> select(:offsets, from: "#select1_div") 
# %{"select1_div" => %{"left" => 454, "top" => 121}}
# iex(11)> socket |> select(:offset, from: "#select1_div") 
# %{"left" => 454, "top" => 121}

    end

  end
end
