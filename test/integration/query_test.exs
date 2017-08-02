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

    test "select/2 and update/2 - attr and prop" do
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

  describe "Drab.Query update" do
    test "text, html and value update/3" do
      socket = drab_socket()
      div = find_element(:id, "select1_div")
      input = find_element(:id, "select1_input")

      socket |> update(:text, set: "updated text", on: "#select1_div")
      # checks the Drab output with Hound output
      assert socket |> select(:text, from: "#select1_div") == visible_text(div)
      assert visible_text(div) == "updated text"

      socket |> update(:html, set: "<b>updated html</b>", on: "#select1_div")
      assert socket |> select(:html, from: "#select1_div") == inner_html(div)
      assert inner_html(div) == "<b>updated html</b>"
      assert socket |> select(:text, from: "#select1_div") == visible_text(div)
      assert visible_text(div) == "updated html"

      socket |> update(:val, set: "updated val", on: "#select1_input")
      assert socket |> select(:val, from: "#select1_input") == attribute_value(input, "value")
      assert attribute_value(input, "value") == "updated val"
    end

    test "more update/3" do
      socket = drab_socket()
      selector = "#select1_div"
      tests = [:width, :height,
               :innerWidth, :innerHeight]
               # TODO: :scrollTop, :scrollLeft are not tested, as it can't be changed (always return 0)
      for method <- tests do
        r = Enum.random(100..200)
        socket |> update(method, set: "#{r}px", on: selector)
        assert socket |> select(method, from: selector) == r
      end
    end

    defp cycle_test(method, selector, list) do
      socket = drab_socket()

      # One more, as the list must cycle
      for expected <- list ++ [List.first(list)] do
        socket |> update(method, set: list, on: selector)
        assert socket |> select(method, from: selector) == expected
      end
    end

    test "cycle update/3 text" do
      cycle_test :text, "#select1_div", ["One", "Two", "Three"]
    end

    test "cycle update/3 text one element" do
      cycle_test :text, "#select1_div", ["One"]
    end

    test "cycle update/3 text zero elements list should not change the value" do
      socket = drab_socket()
      selector = "#select1_div"

      before = socket |> select(:text, from: selector)
      socket |> update(:text, set: [], on: selector)
      assert before == socket |> select(:text, from: selector)
    end

    test "cycle on more than one element should raise an exception" do
      socket = drab_socket()
      selector = "select_div"

      assert_raise ArgumentError, fn ->
        socket |> update(:text, set: ["anything"], on: selector)
      end
    end

    test "cycle update/3 html" do
      cycle_test :html, "#select1_div", ["One", "Two"]
    end

    test "cycle update/3 val" do
      cycle_test :val, "#select1_input", ["One", "Two", "Three", "Four"]
    end

    test "cycle update/3 height" do
      cycle_test :height, "#select1_input", [33, 66, 99]
    end

    test "cycle update/3 width" do
      cycle_test :width, "#select1_input", [33, 66, 99]
    end

    test "update/2 css" do
      socket = drab_socket()
      selector = "#select1_div"
      div = find_element(:id, "select1_div")

      socket |> update(css: "font-size", set: "33px", on: selector )
      ret = socket |> select(css: "font-size", from: selector)
      assert ret == css_property(div, "font-size") 
      assert ret == "33px"
    end

    test "update/2 data" do
      socket = drab_socket()
      selector = "#select1_div"

      socket |> update(data: "testdata", set: "test for data", on: selector )
      ret = socket |> select(data: "testdata", from: selector)
      assert ret == "test for data"
    end

    test "update/2 class replacement" do
      socket = drab_socket()
      selector = "#select1_div"
      div = find_element(:id, "select1_div")

      socket |> update(class: "select_div", set: "replaced-class", on: selector)
      ret = socket |> select(attr: "class", from: selector)
      assert ret == "replaced-class"
      assert has_class?(div, "replaced-class")
      refute has_class?(div, "select_div")
    end

    test "update/2 class toggle" do
      socket = drab_socket()
      selector = "#select2_div"
      div = find_element(:id, "select2_div")

      socket |> update(:class, toggle: "select_div", on: selector)
      refute has_class?(div, "select_div")
      assert has_class?(div, "another")

      socket |> update(:class, toggle: "select_div", on: selector)
      assert has_class?(div, "select_div")
      assert has_class?(div, "another")
    end

    test "update/2 class cycle" do
      socket = drab_socket()
      selector = "#select2_div"
      div = find_element(:id, "select2_div")
      list = ["another", "more", "class"]

      for expected <- list ++ [List.first(list)] do
        assert has_class?(div, expected)
        assert has_class?(div, "select_div")
        socket |> update(:class, set: list, on: selector)
      end
      assert has_class?(div, "more")
      assert has_class?(div, "select_div")
      refute has_class?(div, "another")
      refute has_class?(div, "class")
    end

  end

  describe "Drab.Query insert" do
    defp setup_insert() do 
      {drab_socket(), "#insert1_div", find_element(:id, "insert1_div"), find_element(:id, "insert_wrapper")}
    end

    test "insert/3 append" do
      {socket, selector, div, wrapper} = setup_insert()

      socket |> insert(" appended", append: selector)
      assert visible_text(wrapper) == "Insert DIV appended"
      assert visible_text(div) == "Insert DIV appended"
      assert inner_html(wrapper) |> String.trim() == "<div id=\"insert1_div\">Insert DIV appended</div>"
    end

    test "insert/3 prepend" do
      {socket, selector, div, wrapper} = setup_insert()

      socket |> insert("Prepended ", prepend: selector)
      assert visible_text(wrapper) == "Prepended Insert DIV"
      assert visible_text(div) == "Prepended Insert DIV"
      assert inner_html(wrapper) |> String.trim() == "<div id=\"insert1_div\">Prepended Insert DIV</div>"
    end

    test "insert/3 after" do
      {socket, selector, div, wrapper} = setup_insert()

      socket |> insert(" appended", after: selector)
      assert visible_text(wrapper) == "Insert DIV\nappended"
      assert visible_text(div) == "Insert DIV"
      assert inner_html(wrapper) |> String.trim() == "<div id=\"insert1_div\">Insert DIV</div> appended"
    end

    test "insert/3 before" do
      {socket, selector, div, wrapper} = setup_insert()

      socket |> insert("Prepended ", before: selector)
      assert visible_text(wrapper) == "Prepended\nInsert DIV"
      assert visible_text(div) == "Insert DIV"
      assert inner_html(wrapper) |> String.trim() == "Prepended <div id=\"insert1_div\">Insert DIV</div>"
    end
  end

  describe "Drab.Query delete" do
    defp setup_delete() do 
      {drab_socket(), "#delete1_div", find_element(:id, "delete1_div")}
    end

    test "delete/2 - remove the whole element" do
      {socket, selector, _div} = setup_delete()

      find_element(:id, "delete1_div") # should be there before removing
      # function delete/2 imported from both Drab.Query and Phoenix.ConnTest, call is ambiguous
      socket |> Drab.Query.delete(selector)
      assert_raise Hound.NoSuchElementError, fn ->
        find_element(:id, "delete1_div")
      end
    end

    test "delete/2 - remove the element content" do
      {socket, selector, div} = setup_delete()

      assert visible_text(div) == "Delete DIV"
      socket |> Drab.Query.delete(from: selector)
      assert visible_text(div) == ""
    end

    test "delete/2 - remove the class" do
      {socket, selector, div} = setup_delete()

      assert has_class?(div, "class1")
      assert has_class?(div, "class2")
      socket |> Drab.Query.delete(class: "class2", from: selector)
      assert has_class?(div, "class1")
      refute has_class?(div, "class2")
    end     

    test "delete/2 - remove the attribute" do
      {socket, selector, div} = setup_delete()

      assert has_class?(div, "class1")
      assert has_class?(div, "class2")
      socket |> Drab.Query.delete(attr: "class", from: selector)
      refute has_class?(div, "class1")
      refute has_class?(div, "class2")
    end     

    test "delete/2 - remove the property" do
      {socket, selector, _div} = setup_delete()

      socket |> update(prop: "p1", set: "new", on: selector)
      assert socket |> select(prop: "p1", from: selector) == "new"
      socket |> Drab.Query.delete(prop: "p1", from: selector)
      assert socket |> select(prop: "p1", from: selector) == nil
    end     
  end

  describe "Drab.Query execute" do
    defp setup_execute() do 
      {drab_socket(), "#execute1_input", find_element(:id, "execute1_input")}
    end

    test "execute/2 - some other jQuery functions: focus" do
      {socket, selector, input} = setup_execute()

      refute input == element_in_focus()
      socket |> execute(:focus, on: selector)
      assert input == element_in_focus()
    end

    test "execute/2 - some other jQuery functions: toggle" do
      {socket, selector, input} = setup_execute()

      assert element_displayed?(input)
      socket |> execute(:toggle, on: selector)
      refute element_displayed?(input)
    end
  end

  test "dom_sender data transformation" do
    click_and_wait("data_test_button")
    socket = drab_socket()
    assert select(socket, :text, from: "#data_test_div_out1") == "true"
    assert select(socket, :text, from: "#data_test_div_out2") == "true"
  end
end
