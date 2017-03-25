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

    test "extended select/3" do
      # this test does not check the exact return of jquery method
      socket = drab_socket()
      ret = socket |> select(:width, from: "#select1_div")
      # IO.puts ret

# iex(5)> socket |> select(:width, from: "#select1_div")
# 700
# iex(6)> socket |> select(:width, from: "#select1_divx")
# nil
# iex(7)> socket |> select(:innerWidth, from: "#select1_div")
# 700
# iex(8)> socket |> select(:innerWidths, from: "#select1_div")
# %{"select1_div" => 700}
# iex(9)> socket |> select(:position, from: "#select1_div")   
# %{"left" => 454, "top" => 121}
# iex(10)> socket |> select(:offsets, from: "#select1_div") 
# %{"select1_div" => %{"left" => 454, "top" => 121}}
# iex(11)> socket |> select(:offset, from: "#select1_div") 
# %{"left" => 454, "top" => 121}
# iex(12)> socket |> select(:scrollTop, from: "#select1_div")
# 0


    end

  end
end
