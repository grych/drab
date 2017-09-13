defmodule Drab.Live.HtmlTest do
  use ExUnit.Case, ascync: true
  import Drab.Live.HTML
  doctest Drab.Live.HTML

  @buffer ["\n<span drab-ampere=\"gezdamzqg43damq\" drab-partial='guzdmmrvga4de'>\n",
 "<div id=\"begin\" style=\"display: none;\"></div>\n<div id='drab_pid' style=\"display: none;\"></div>\n<span test-span></span>\nurl: ",
 "{{{{@drab-expr-hash:guydsnjqgmydo}}}}",
 {:case, [generated: true],
  [{{:., [line: 4],
     [{:__aliases__, [line: 4, alias: false], [:Phoenix, :HTML, :Engine]},
      :fetch_assign]}, [line: 4],
    [{:var!, [line: 4, context: Drab.Live.EExEngine, import: Kernel],
      [{:assigns, [line: 4], Drab.Live.EExEngine}]}, :url]},
   [do: [{:->, [generated: true],
      [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
       {:data, [generated: true], Drab.Live.EExEngine}]},
     {:->, [generated: true],
      [[{:when, [generated: true],
         [{:bin, [generated: true], Drab.Live.EExEngine},
          {:is_binary,
           [generated: true, context: Drab.Live.EExEngine, import: Kernel],
           [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
       {{:., [generated: true],
         [{:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
          :html_escape]}, [generated: true],
        [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
     {:->, [generated: true],
      [[{:other, [generated: true], Drab.Live.EExEngine}],
       {{:., [line: 4],
         [{:__aliases__, [line: 4, alias: false], [:Phoenix, :HTML, :Safe]},
          :to_iodata]}, [line: 4],
        [{:other, [line: 4], Drab.Live.EExEngine}]}]}]]]},
 "{{{{/@drab-expr-hash:guydsnjqgmydo}}}}", " <br>\n",
 "{{{{@drab-expr-hash:geztaobxge2donq}}}}",
 {:case, [generated: true],
  [{:if, [line: 5],
    [true,
     [do: {:safe,
       [[["", "\n  <span drab-ampere=\"g42tmnbygyydi\">\n    link: "],
         "{{{{@drab-expr-hash:g43denzygq3ti}}}}",
         {:case, [generated: true],
          [{{:., [line: 7],
             [{:__aliases__, [line: 7, alias: false],
               [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, [line: 7],
            [{:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
              [{:assigns, [line: 7], Drab.Live.EExEngine}]}, :link]},
           [do: [{:->, [generated: true],
              [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
               {:data, [generated: true], Drab.Live.EExEngine}]},
             {:->, [generated: true],
              [[{:when, [generated: true],
                 [{:bin, [generated: true], Drab.Live.EExEngine},
                  {:is_binary,
                   [generated: true, context: Drab.Live.EExEngine,
                    import: Kernel],
                   [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
               {{:., [generated: true],
                 [{:__aliases__, [generated: true, alias: false],
                   [:Plug, :HTML]}, :html_escape]}, [generated: true],
                [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
             {:->, [generated: true],
              [[{:other, [generated: true], Drab.Live.EExEngine}],
               {{:., [line: 7],
                 [{:__aliases__, [line: 7, alias: false],
                   [:Phoenix, :HTML, :Safe]}, :to_iodata]}, [line: 7],
                [{:other, [line: 7], Drab.Live.EExEngine}]}]}]]]},
         "{{{{/@drab-expr-hash:g43denzygq3ti}}}}"], "\n  </span>\n"]}]]},
   [do: [{:->, [generated: true],
      [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
       {:data, [generated: true], Drab.Live.EExEngine}]},
     {:->, [generated: true],
      [[{:when, [generated: true],
         [{:bin, [generated: true], Drab.Live.EExEngine},
          {:is_binary,
           [generated: true, context: Drab.Live.EExEngine, import: Kernel],
           [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
       {{:., [generated: true],
         [{:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
          :html_escape]}, [generated: true],
        [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
     {:->, [generated: true],
      [[{:other, [generated: true], Drab.Live.EExEngine}],
       {{:., [line: 5],
         [{:__aliases__, [line: 5, alias: false], [:Phoenix, :HTML, :Safe]},
          :to_iodata]}, [line: 5],
        [{:other, [line: 5], Drab.Live.EExEngine}]}]}]]]},
 "{{{{/@drab-expr-hash:geztaobxge2donq}}}}", "\n", "\n</span>\n"]

  @buffer_with_attributes ["\n<span drab-ampere=\"gy2deojsg4yq\" drab-partial='guzdmmrvga4de'>\n",
 "<span drab-ampere=\"geytcobwgq3dinq\" test-span url=",
 "{{{{@drab-expr-hash:ge2tgmzxhazte}}}}",
 {:case, [generated: true],
  [{{:., [line: 3],
     [{:__aliases__, [line: 3, alias: false], [:Phoenix, :HTML, :Engine]},
      :fetch_assign]}, [line: 3],
    [{:var!, [line: 3, context: Drab.Live.EExEngine, import: Kernel],
      [{:assigns, [line: 3], Drab.Live.EExEngine}]}, :url]},
   [do: [{:->, [generated: true],
      [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
       {:data, [generated: true], Drab.Live.EExEngine}]},
     {:->, [generated: true],
      [[{:when, [generated: true],
         [{:bin, [generated: true], Drab.Live.EExEngine},
          {:is_binary,
           [generated: true, context: Drab.Live.EExEngine, import: Kernel],
           [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
       {{:., [generated: true],
         [{:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
          :html_escape]}, [generated: true],
        [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
     {:->, [generated: true],
      [[{:other, [generated: true], Drab.Live.EExEngine}],
       {{:., [line: 3],
         [{:__aliases__, [line: 3, alias: false], [:Phoenix, :HTML, :Safe]},
          :to_iodata]}, [line: 3],
        [{:other, [line: 3], Drab.Live.EExEngine}]}]}]]]},
 "{{{{/@drab-expr-hash:ge2tgmzxhazte}}}}", ">inside span</span>\n",
 "{{{{@drab-expr-hash:geytmnrzha4dkna}}}}",
 {:case, [generated: true],
  [{:if, [line: 4],
    [true,
     [do: {:safe,
       [[[[["", "\n  <div drab-ampere=\"gmztanrwge2tm\" @link='"],
           "{{{{@drab-expr-hash:gezdmmrrgi3damy}}}}",
           {:case, [generated: true],
            [{{:., [line: 5],
               [{:__aliases__, [line: 5, alias: false],
                 [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, [line: 5],
              [{:var!, [line: 5, context: Drab.Live.EExEngine, import: Kernel],
                [{:assigns, [line: 5], Drab.Live.EExEngine}]}, :link]},
             [do: [{:->, [generated: true],
                [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
                 {:data, [generated: true], Drab.Live.EExEngine}]},
               {:->, [generated: true],
                [[{:when, [generated: true],
                   [{:bin, [generated: true], Drab.Live.EExEngine},
                    {:is_binary,
                     [generated: true, context: Drab.Live.EExEngine,
                      import: Kernel],
                     [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
                 {{:., [generated: true],
                   [{:__aliases__, [generated: true, alias: false],
                     [:Plug, :HTML]}, :html_escape]}, [generated: true],
                  [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
               {:->, [generated: true],
                [[{:other, [generated: true], Drab.Live.EExEngine}],
                 {{:., [line: 5],
                   [{:__aliases__, [line: 5, alias: false],
                     [:Phoenix, :HTML, :Safe]}, :to_iodata]}, [line: 5],
                  [{:other, [line: 5], Drab.Live.EExEngine}]}]}]]]},
           "{{{{/@drab-expr-hash:gezdmmrrgi3damy}}}}"], "'>\n    inside div: "],
         "{{{{@drab-expr-hash:gy2tmnbtge2tq}}}}",
         {:case, [generated: true],
          [{{:., [line: 6],
             [{:__aliases__, [line: 6, alias: false],
               [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, [line: 6],
            [{:var!, [line: 6, context: Drab.Live.EExEngine, import: Kernel],
              [{:assigns, [line: 6], Drab.Live.EExEngine}]}, :link]},
           [do: [{:->, [generated: true],
              [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
               {:data, [generated: true], Drab.Live.EExEngine}]},
             {:->, [generated: true],
              [[{:when, [generated: true],
                 [{:bin, [generated: true], Drab.Live.EExEngine},
                  {:is_binary,
                   [generated: true, context: Drab.Live.EExEngine,
                    import: Kernel],
                   [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
               {{:., [generated: true],
                 [{:__aliases__, [generated: true, alias: false],
                   [:Plug, :HTML]}, :html_escape]}, [generated: true],
                [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
             {:->, [generated: true],
              [[{:other, [generated: true], Drab.Live.EExEngine}],
               {{:., [line: 6],
                 [{:__aliases__, [line: 6, alias: false],
                   [:Phoenix, :HTML, :Safe]}, :to_iodata]}, [line: 6],
                [{:other, [line: 6], Drab.Live.EExEngine}]}]}]]]},
         "{{{{/@drab-expr-hash:gy2tmnbtge2tq}}}}"], "\n  </div>\n"]}]]},
   [do: [{:->, [generated: true],
      [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
       {:data, [generated: true], Drab.Live.EExEngine}]},
     {:->, [generated: true],
      [[{:when, [generated: true],
         [{:bin, [generated: true], Drab.Live.EExEngine},
          {:is_binary,
           [generated: true, context: Drab.Live.EExEngine, import: Kernel],
           [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
       {{:., [generated: true],
         [{:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
          :html_escape]}, [generated: true],
        [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
     {:->, [generated: true],
      [[{:other, [generated: true], Drab.Live.EExEngine}],
       {{:., [line: 4],
         [{:__aliases__, [line: 4, alias: false], [:Phoenix, :HTML, :Safe]},
          :to_iodata]}, [line: 4],
        [{:other, [line: 4], Drab.Live.EExEngine}]}]}]]]},
 "{{{{/@drab-expr-hash:geytmnrzha4dkna}}}}", "\n", "\n</span>\n",
 "<script drab-script>",
 "if (typeof window.__drab == 'undefined') {window.__drab = {assigns: {}}};\nwindow.__drab.assigns['guzdmmrvga4de'] = {};\n",
 "</script>", "<script drab-script>",
 "__drab.assigns['guzdmmrvga4de']['link'] = '",
 {{:., [[generated: true]],
   [{:__aliases__, [[generated: true]], [:Drab, :Live, :Crypto]}, :encode64]},
  [[generated: true]],
  [{{:., [line: 0],
     [{:__aliases__, [line: 0, alias: false], [:Phoenix, :HTML, :Engine]},
      :fetch_assign]}, [line: 0],
    [{:var!, [line: 0, context: Drab.Live.EExEngine, import: Kernel],
      [{:assigns, [line: 0], Drab.Live.EExEngine}]}, :link]}]}, "';",
 "__drab.assigns['guzdmmrvga4de']['url'] = '",
 {{:., [[generated: true]],
   [{:__aliases__, [[generated: true]], [:Drab, :Live, :Crypto]}, :encode64]},
  [[generated: true]],
  [{{:., [line: 0],
     [{:__aliases__, [line: 0, alias: false], [:Phoenix, :HTML, :Engine]},
      :fetch_assign]}, [line: 0],
    [{:var!, [line: 0, context: Drab.Live.EExEngine, import: Kernel],
      [{:assigns, [line: 0], Drab.Live.EExEngine}]}, :url]}]}, "';",
 "</script>"]

  @inner_safe {:safe,
       [[["", "\n  <span drab-ampere=\"g42tmnbygyydi\">\n    link: "],
         "{{{{@drab-expr-hash:g43denzygq3ti}}}}",
         {:case, [generated: true],
          [{{:., [line: 7],
             [{:__aliases__, [line: 7, alias: false],
               [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, [line: 7],
            [{:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
              [{:assigns, [line: 7], Drab.Live.EExEngine}]}, :link]},
           [do: [{:->, [generated: true],
              [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
               {:data, [generated: true], Drab.Live.EExEngine}]},
             {:->, [generated: true],
              [[{:when, [generated: true],
                 [{:bin, [generated: true], Drab.Live.EExEngine},
                  {:is_binary,
                   [generated: true, context: Drab.Live.EExEngine,
                    import: Kernel],
                   [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
               {{:., [generated: true],
                 [{:__aliases__, [generated: true, alias: false],
                   [:Plug, :HTML]}, :html_escape]}, [generated: true],
                [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
             {:->, [generated: true],
              [[{:other, [generated: true], Drab.Live.EExEngine}],
               {{:., [line: 7],
                 [{:__aliases__, [line: 7, alias: false],
                   [:Phoenix, :HTML, :Safe]}, :to_iodata]}, [line: 7],
                [{:other, [line: 7], Drab.Live.EExEngine}]}]}]]]},
         "{{{{/@drab-expr-hash:g43denzygq3ti}}}}"], "\n  </span>\n"]}

  @inner_expr [false, [{:do, {:safe,
       [[["", "\n  <span drab-ampere=\"g42tmnbygyydi\">\n    link: "],
         "{{{{@drab-expr-hash:g43denzygq3ti}}}}",
         {:case, [generated: true],
          [{{:., [line: 7],
             [{:__aliases__, [line: 7, alias: false],
               [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, [line: 7],
            [{:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
              [{:assigns, [line: 7], Drab.Live.EExEngine}]}, :link]},
           [do: [{:->, [generated: true],
              [[safe: {:data, [generated: true], Drab.Live.EExEngine}],
               {:data, [generated: true], Drab.Live.EExEngine}]},
             {:->, [generated: true],
              [[{:when, [generated: true],
                 [{:bin, [generated: true], Drab.Live.EExEngine},
                  {:is_binary,
                   [generated: true, context: Drab.Live.EExEngine,
                    import: Kernel],
                   [{:bin, [generated: true], Drab.Live.EExEngine}]}]}],
               {{:., [generated: true],
                 [{:__aliases__, [generated: true, alias: false],
                   [:Plug, :HTML]}, :html_escape]}, [generated: true],
                [{:bin, [generated: true], Drab.Live.EExEngine}]}]},
             {:->, [generated: true],
              [[{:other, [generated: true], Drab.Live.EExEngine}],
               {{:., [line: 7],
                 [{:__aliases__, [line: 7, alias: false],
                   [:Phoenix, :HTML, :Safe]}, :to_iodata]}, [line: 7],
                [{:other, [line: 7], Drab.Live.EExEngine}]}]}]]]},
         "{{{{/@drab-expr-hash:g43denzygq3ti}}}}"], "\n  </span>\n"]}}]]

  test "to flat html" do
    assert to_flat_html(@buffer) == """

      <span drab-ampere="gezdamzqg43damq" drab-partial='guzdmmrvga4de'>
      <div id="begin" style="display: none;"></div>
      <div id='drab_pid' style="display: none;"></div>
      <span test-span></span>
      url: {{{{@drab-expr-hash:guydsnjqgmydo}}}}{{{{/@drab-expr-hash:guydsnjqgmydo}}}} <br>
      {{{{@drab-expr-hash:geztaobxge2donq}}}}{{{{/@drab-expr-hash:geztaobxge2donq}}}}

      </span>
      """
    assert to_flat_html(@inner_safe) == """

      <span drab-ampere=\"g42tmnbygyydi\">
        link: {{{{@drab-expr-hash:g43denzygq3ti}}}}{{{{/@drab-expr-hash:g43denzygq3ti}}}}
      </span>
    """
  end

  test "amperes and patterns from buffer" do
    buffer = {:safe, @buffer}
    assert amperes_from_buffer(buffer) == %{
      "gezdamzqg43damq" => [{:html, "span","""
        <div id="begin" style="display: none;"></div><div id="drab_pid" style="display: none;"></div><span test-span="test-span"></span>
        url: {{{{@drab-expr-hash:guydsnjqgmydo}}}}{{{{/@drab-expr-hash:guydsnjqgmydo}}}} <br/>
        {{{{@drab-expr-hash:geztaobxge2donq}}}}{{{{/@drab-expr-hash:geztaobxge2donq}}}}

        """}],
      "g42tmnbygyydi" => [{:html, "span",
        "\n    link: {{{{@drab-expr-hash:g43denzygq3ti}}}}{{{{/@drab-expr-hash:g43denzygq3ti}}}}\n  "}]}
  end

  test "amperes and patters from small inner expression" do
    assert amperes_from_buffer(@inner_expr) == %{"g42tmnbygyydi" => [{:html, "span",
      "\n    link: {{{{@drab-expr-hash:g43denzygq3ti}}}}{{{{/@drab-expr-hash:g43denzygq3ti}}}}\n  "}]}
  end

  test "amperes and attributes from buffer" do
    assert amperes_from_buffer({:safe, @buffer_with_attributes}) == %{"geytcobwgq3dinq" => [{:attr, "span", "url",
      "{{{{@drab-expr-hash:ge2tgmzxhazte}}}}{{{{/@drab-expr-hash:ge2tgmzxhazte}}}}"}],
    "gmztanrwge2tm" => [{:html, "div",
      "\n    inside div: {{{{@drab-expr-hash:gy2tmnbtge2tq}}}}{{{{/@drab-expr-hash:gy2tmnbtge2tq}}}}\n  "},
     {:attr, "div", "@link",
      "{{{{@drab-expr-hash:gezdmmrrgi3damy}}}}{{{{/@drab-expr-hash:gezdmmrrgi3damy}}}}"}],
    "gy2deojsg4yq" => [{:html, "span",
      "<span drab-ampere=\"geytcobwgq3dinq\" test-span=\"test-span\" \
url=\"{{{{@drab-expr-hash:ge2tgmzxhazte}}}}{{{{/@drab-expr-hash:ge2tgmzxhazte}}}}\">\
inside span</span>\n{{{{@drab-expr-hash:geytmnrzha4dkna}}}}{{{{/@drab-expr-hash:geytmnrzha4dkna}}}}\n\n"}]}
  end

  test "simple inject attribute" do
    assert inject_attribute_to_last_opened("<span attr=span></span><tag attrx=2>", "attr=1")
      == {:ok, "<span attr=span></span><tag attr=1 attrx=2>", "attr=1"}
  end

  test "inject attribute when closed at the beginning" do
    assert inject_attribute_to_last_opened(" ></span><tag attrx=2>", "attr=1")
      == {:ok, " ></span><tag attr=1 attrx=2>", "attr=1"}
  end

  test "inject attribute when closed at the beginning (already there)" do
    assert inject_attribute_to_last_opened(" ></span><tag attr=2>", "attr=1")
      == {:already_there, " ></span><tag attr=2>", "attr=2"}
  end

@inject_after_attribute_buffer ["\n<span drab-partial='guzdmmrvga4de'>\n",
  "<div id=\"begin\"></div>\n<div></div>\n<span drab-ampere=\"geytcobwgq3dinq\" test-span url=",
  ">inside span</span>\n<div>\n  inside div: "]

  test "inject after attribute from string" do
    assert inject_attribute_to_last_opened(@inject_after_attribute_buffer, "drab-ampere=ampere") == {:ok,
             ["\n<span drab-partial='guzdmmrvga4de'>\n",
              "<div id=\"begin\"></div>\n<div></div>\n<span drab-ampere=\"geytcobwgq3dinq\" test-span url=",
              ">inside span</span>\n<div drab-ampere=ampere>\n  inside div: "],
             "drab-ampere=ampere"}
  end
end
