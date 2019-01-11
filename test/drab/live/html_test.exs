defmodule Drab.Live.HtmlTest do
  use ExUnit.Case, ascync: true
  import Drab.Live.HTML
  doctest Drab.Live.HTML

  @simple_buffer [
    {:__block__, [],
     [
       {:=, [],
        [
          {:tmp1, [], Drab.Live.EExEngine},
          [
            "\n<span drab-partial='gi3tgnrzg44tmnbs'>\n",
            "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\">\
</div>\n\n<div covers-color-and-link>\n\n  <span before-color>\n    "
          ]
        ]},
       [
         {:tmp1, [], Drab.Live.EExEngine},
         "{{{{@drab-expr-hash:gi3tgmjvgy2tonjx}}}}",
         {:case, [generated: true],
          [
            {{:., [line: 7],
              [{:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Engine]}, :fetch_assign!]},
             [line: 7],
             [
               {:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
                [{:assigns, [line: 7], Drab.Live.EExEngine}]},
               :color
             ]},
            [
              do: [
                {:->, [generated: true],
                 [
                   [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                   {:data, [generated: true], Drab.Live.EExEngine}
                 ]},
                {:->, [generated: true],
                 [
                   [
                     {:when, [generated: true],
                      [
                        {:bin, [generated: true], Drab.Live.EExEngine},
                        {:is_binary,
                         [generated: true, context: Drab.Live.EExEngine, import: Kernel],
                         [{:bin, [generated: true], Drab.Live.EExEngine}]}
                      ]}
                   ],
                   {{:., [generated: true],
                     [
                       {:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
                       :html_escape
                     ]}, [generated: true], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                 ]},
                {:->, [generated: true],
                 [
                   [{:other, [generated: true], Drab.Live.EExEngine}],
                   {{:., [line: 7],
                     [
                       {:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Safe]},
                       :to_iodata
                     ]}, [line: 7], [{:other, [line: 7], Drab.Live.EExEngine}]}
                 ]}
              ]
            ]
          ]},
         "{{{{/@drab-expr-hash:gi3tgmjvgy2tonjx}}}}"
       ]
     ]},
    "\n  </span>\n\n  "
  ]

  @simple_buffer_with_attribute [
    {:__block__, [],
     [
       {:=, [],
        [
          {:tmp1, [], Drab.Live.EExEngine},
          [
            "\n<span drab-partial='gi3tgnrzg44tmnbs'>\n",
            "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\">\
</div>\n\n<div drab-ampere=\"ge2tamztgq3tcny\" covers-color-and-link>\n\n  <span before-color>\n    "
          ]
        ]},
       [
         {:tmp1, [], Drab.Live.EExEngine},
         "{{{{@drab-expr-hash:gi3tgmjvgy2tonjx}}}}",
         {:case, [generated: true],
          [
            {{:., [line: 7],
              [{:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Engine]}, :fetch_assign!]},
             [line: 7],
             [
               {:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
                [{:assigns, [line: 7], Drab.Live.EExEngine}]},
               :color
             ]},
            [
              do: [
                {:->, [generated: true],
                 [
                   [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                   {:data, [generated: true], Drab.Live.EExEngine}
                 ]},
                {:->, [generated: true],
                 [
                   [
                     {:when, [generated: true],
                      [
                        {:bin, [generated: true], Drab.Live.EExEngine},
                        {:is_binary,
                         [generated: true, context: Drab.Live.EExEngine, import: Kernel],
                         [{:bin, [generated: true], Drab.Live.EExEngine}]}
                      ]}
                   ],
                   {{:., [generated: true],
                     [
                       {:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
                       :html_escape
                     ]}, [generated: true], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                 ]},
                {:->, [generated: true],
                 [
                   [{:other, [generated: true], Drab.Live.EExEngine}],
                   {{:., [line: 7],
                     [
                       {:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Safe]},
                       :to_iodata
                     ]}, [line: 7], [{:other, [line: 7], Drab.Live.EExEngine}]}
                 ]}
              ]
            ]
          ]},
         "{{{{/@drab-expr-hash:gi3tgmjvgy2tonjx}}}}"
       ]
     ]},
    "\n  </span>\n\n  "
  ]

  # test "flat html from simple buffer" do
  #   assert to_flat_html(@simple_buffer) == ""
  # end

  test "deep reverse simple buffer" do
    assert deep_reverse(deep_reverse(@simple_buffer)) == @simple_buffer
  end

  test "tokenize and detokenize simple buffer" do
    assert tokenized_to_html(tokenize(@simple_buffer)) == @simple_buffer

    assert tokenized_to_html(tokenize(@simple_buffer_with_attribute)) ==
             @simple_buffer_with_attribute
  end

  test "inject attribute to simple buffer" do
    attribute = "drab-ampere=\"ge2tamztgq3tcny\""

    assert inject_attribute_to_last_opened(@simple_buffer, attribute) ==
             {:ok, @simple_buffer_with_attribute, "drab-ampere=\"ge2tamztgq3tcny\""}
  end

  test "injecting attribute is already there" do
    assert inject_attribute_to_last_opened(
             @simple_buffer_with_attribute,
             "drab-ampere=test-ampere"
           ) == {:already_there, @simple_buffer_with_attribute, "drab-ampere=\"ge2tamztgq3tcny\""}
  end

  test "amperes from simple buffer" do
    assert amperes_from_buffer({:safe, @simple_buffer_with_attribute}) ==
             %{
               "ge2tamztgq3tcny" => [
                 {:html, "div", "innerHTML", "<span before-color=\"before-color\">\n\
    {{{{@drab-expr-hash:gi3tgmjvgy2tonjx}}}}{{{{/@drab-expr-hash:gi3tgmjvgy2tonjx}}}}\n  </span>"}
               ]
             }
  end

  test "case sensitive property name" do
    assert case_sensitive_prop_name(
             "<tag drab-ampere=\"AMP\" @Property=value>",
             "AMP",
             "property"
           ) == "Property"

    assert case_sensitive_prop_name(
             "<tag drab-ampere=\"AMP\" @property=value>",
             "AMP",
             "property"
           ) == "property"

    assert case_sensitive_prop_name(
             "<tag drab-ampere=\"AMP\" @Property=value @property=value>",
             "AMP",
             "property"
           ) == "Property"
  end

  @full_buffer [
    {:__block__, [],
     [
       {:=, [],
        [
          {:tmp1, [], Drab.Live.EExEngine},
          [
            "\n<span drab-partial='gi3tgnrzg44tmnbs'>\n",
            "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\"></div>\n\n<div covers-color-and-link>\n\n  "
          ]
        ]},
       [
         {:tmp1, [], Drab.Live.EExEngine},
         {:case, [generated: true],
          [
            {:if, [line: 6],
             [
               true,
               [
                 do:
                   {:safe,
                    [
                      {:__block__, [],
                       [
                         {:=, [],
                          [
                            {:tmp1, [], Drab.Live.EExEngine},
                            ["", "\n    <b drab-ampere=\"gi4donzwg42tinbw\">\n      "]
                          ]},
                         [
                           {:tmp1, [], Drab.Live.EExEngine},
                           "{{{{@drab-expr-hash:geztcmrqgmzteobq}}}}",
                           {:case, [generated: true],
                            [
                              {{:., [line: 8],
                                [
                                  {:__aliases__, [line: 8, alias: false],
                                   [:Phoenix, :HTML, :Engine]},
                                  :fetch_assign
                                ]}, [line: 8],
                               [
                                 {:var!, [line: 8, context: Drab.Live.EExEngine, import: Kernel],
                                  [{:assigns, [line: 8], Drab.Live.EExEngine}]},
                                 :link
                               ]},
                              [
                                do: [
                                  {:->, [generated: true],
                                   [
                                     [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                                     {:data, [generated: true], Drab.Live.EExEngine}
                                   ]},
                                  {:->, [generated: true],
                                   [
                                     [
                                       {:when, [generated: true],
                                        [
                                          {:bin, [generated: true], Drab.Live.EExEngine},
                                          {:is_binary,
                                           [
                                             generated: true,
                                             context: Drab.Live.EExEngine,
                                             import: Kernel
                                           ], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                                        ]}
                                     ],
                                     {{:., [generated: true],
                                       [
                                         {:__aliases__, [generated: true, alias: false],
                                          [:Plug, :HTML]},
                                         :html_escape
                                       ]}, [generated: true],
                                      [{:bin, [generated: true], Drab.Live.EExEngine}]}
                                   ]},
                                  {:->, [generated: true],
                                   [
                                     [{:other, [generated: true], Drab.Live.EExEngine}],
                                     {{:., [line: 8],
                                       [
                                         {:__aliases__, [line: 8, alias: false],
                                          [:Phoenix, :HTML, :Safe]},
                                         :to_iodata
                                       ]}, [line: 8], [{:other, [line: 8], Drab.Live.EExEngine}]}
                                   ]}
                                ]
                              ]
                            ]},
                           "{{{{/@drab-expr-hash:geztcmrqgmzteobq}}}}"
                         ]
                       ]},
                      "\n    </b>\n  "
                    ]}
               ]
             ]},
            [
              do: [
                {:->, [generated: true],
                 [
                   [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                   {:data, [generated: true], Drab.Live.EExEngine}
                 ]},
                {:->, [generated: true],
                 [
                   [
                     {:when, [generated: true],
                      [
                        {:bin, [generated: true], Drab.Live.EExEngine},
                        {:is_binary,
                         [generated: true, context: Drab.Live.EExEngine, import: Kernel],
                         [{:bin, [generated: true], Drab.Live.EExEngine}]}
                      ]}
                   ],
                   {{:., [generated: true],
                     [
                       {:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
                       :html_escape
                     ]}, [generated: true], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                 ]},
                {:->, [generated: true],
                 [
                   [{:other, [generated: true], Drab.Live.EExEngine}],
                   {{:., [line: 6],
                     [
                       {:__aliases__, [line: 6, alias: false], [:Phoenix, :HTML, :Safe]},
                       :to_iodata
                     ]}, [line: 6], [{:other, [line: 6], Drab.Live.EExEngine}]}
                 ]}
              ]
            ]
          ]}
       ]
     ]},
    "\n\n</div>\n\n<button drab-click=update_mini>Update mini</button>\n"
  ]

  test "full buffer to flat html" do
    assert to_flat_html(@full_buffer) == """

           <span drab-partial='gi3tgnrzg44tmnbs'>
           <div id=\"begin\" style=\"display: none;\"></div>
           <div id=\"drab_pid\" style=\"display: none;\"></div>

           <div covers-color-and-link>

             \n    <b drab-ampere=\"gi4donzwg42tinbw\">
                 {{{{@drab-expr-hash:geztcmrqgmzteobq}}}}{{{{/@drab-expr-hash:geztcmrqgmzteobq}}}}
               </b>\n  \n\n</div>

           <button drab-click=update_mini>Update mini</button>
           """
  end

  @buffer_with_no_output_expression [
    {:__block__, [],
     [
       {:=, [],
        [
          {:tmp1, [], Drab.Live.EExEngine},
          [
            {:__block__, [],
             [
               {:=, [],
                [
                  {:tmp2, [], Drab.Live.EExEngine},
                  [
                    "\n<span drab-partial='gi3tgnrzg44tmnbs'>\n",
                    "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\">\
</div>\n\n<div drab-ampere=\"giytinrsgi2tqobu\">\n"
                  ]
                ]},
               {:=, [line: 5], [{:a, [line: 5], nil}, "dupaX"]},
               {:tmp2, [], Drab.Live.EExEngine}
             ]},
            "\n<br>\n"
          ]
        ]},
       [
         {:tmp1, [], Drab.Live.EExEngine},
         "{{{{@drab-expr-hash:gu3tgmzrgq4deoa}}}}",
         {:case, [generated: true],
          [
            {{:., [line: 7],
              [{:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Engine]}, :!]},
             [line: 7],
             [
               {:var!, [line: 7, context: Drab.Live.EExEngine, import: Kernel],
                [{:assigns, [line: 7], Drab.Live.EExEngine}]},
               :link
             ]},
            [
              do: [
                {:->, [generated: true],
                 [
                   [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                   {:data, [generated: true], Drab.Live.EExEngine}
                 ]},
                {:->, [generated: true],
                 [
                   [
                     {:when, [generated: true],
                      [
                        {:bin, [generated: true], Drab.Live.EExEngine},
                        {:is_binary,
                         [generated: true, context: Drab.Live.EExEngine, import: Kernel],
                         [{:bin, [generated: true], Drab.Live.EExEngine}]}
                      ]}
                   ],
                   {{:., [generated: true],
                     [
                       {:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
                       :html_escape
                     ]}, [generated: true], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                 ]},
                {:->, [generated: true],
                 [
                   [{:other, [generated: true], Drab.Live.EExEngine}],
                   {{:., [line: 7],
                     [
                       {:__aliases__, [line: 7, alias: false], [:Phoenix, :HTML, :Safe]},
                       :to_iodata
                     ]}, [line: 7], [{:other, [line: 7], Drab.Live.EExEngine}]}
                 ]}
              ]
            ]
          ]},
         "{{{{/@drab-expr-hash:gu3tgmzrgq4deoa}}}}"
       ]
     ]},
    "\n</div>\n\n<button drab-click=update_mini>Update mini</button>\n"
  ]

  test "buffer with no outputting expression to flat html" do
    assert to_flat_html(@buffer_with_no_output_expression) ==
             "\n<span drab-partial='gi3tgnrzg44tmnbs'>\n<div id=\"begin\" style=\"display: none;\"></div>\
\n<div id=\"drab_pid\" style=\"display: none;\"></div>\n\n<div drab-ampere=\"giytinrsgi2tqobu\">\n\n<br>\
\n{{{{@drab-expr-hash:gu3tgmzrgq4deoa}}}}{{{{/@drab-expr-hash:gu3tgmzrgq4deoa}}}}\n</div>\n\n\
<button drab-click=update_mini>Update mini</button>\n"
  end

  @buffer_with_sigil [
    {:__block__, [],
     [
       {:=, [],
        [
          {:tmp1, [], Drab.Live.EExEngine},
          [
            "{{{{@drab-partial:gi3tgnrzg44tmnbs}}}}",
            "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\"></div>\n\n"
          ]
        ]},
       [
         {:tmp1, [], Drab.Live.EExEngine},
         {:case, [generated: true],
          [
            {:sigil_s, [line: 4], [{:<<>>, [line: 4], ["\"dupa\""]}, []]},
            [
              do: [
                {:->, [generated: true],
                 [
                   [safe: {:data, [generated: true], Drab.Live.EExEngine}],
                   {:data, [generated: true], Drab.Live.EExEngine}
                 ]},
                {:->, [generated: true],
                 [
                   [
                     {:when, [generated: true],
                      [
                        {:bin, [generated: true], Drab.Live.EExEngine},
                        {:is_binary,
                         [generated: true, context: Drab.Live.EExEngine, import: Kernel],
                         [{:bin, [generated: true], Drab.Live.EExEngine}]}
                      ]}
                   ],
                   {{:., [generated: true],
                     [
                       {:__aliases__, [generated: true, alias: false], [:Plug, :HTML]},
                       :html_escape
                     ]}, [generated: true], [{:bin, [generated: true], Drab.Live.EExEngine}]}
                 ]},
                {:->, [generated: true],
                 [
                   [{:other, [generated: true], Drab.Live.EExEngine}],
                   {{:., [line: 4],
                     [
                       {:__aliases__, [line: 4, alias: false], [:Phoenix, :HTML, :Safe]},
                       :to_iodata
                     ]}, [line: 4], [{:other, [line: 4], Drab.Live.EExEngine}]}
                 ]}
              ]
            ]
          ]}
       ]
     ]},
    "\n<p>\n"
  ]

  test "buffer with sigil should be preserved while tokenize" do
    assert tokenized_to_html(tokenize(@buffer_with_sigil)) == @buffer_with_sigil
  end
end
