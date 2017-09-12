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
      "gezdamzqg43damq" => {:html, "span","""
        <div id="begin" style="display: none;"></div><div id="drab_pid" style="display: none;"></div><span test-span="test-span"></span>
        url: {{{{@drab-expr-hash:guydsnjqgmydo}}}}{{{{/@drab-expr-hash:guydsnjqgmydo}}}} <br/>
        {{{{@drab-expr-hash:geztaobxge2donq}}}}{{{{/@drab-expr-hash:geztaobxge2donq}}}}

        """},
      "g42tmnbygyydi" => {:html, "span",
        "\n    link: {{{{@drab-expr-hash:g43denzygq3ti}}}}{{{{/@drab-expr-hash:g43denzygq3ti}}}}\n  "}}
  end

  test "amperes and patters from small inner expression" do
    assert amperes_from_buffer(@inner_expr) == %{"g42tmnbygyydi" => {:html, "span",
      "\n    link: {{{{@drab-expr-hash:g43denzygq3ti}}}}{{{{/@drab-expr-hash:g43denzygq3ti}}}}\n  "}}
  end
end
