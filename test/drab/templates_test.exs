defmodule Drab.TemplateTest do
  use ExUnit.Case, ascync: true
  import Drab.Template
  doctest Drab.Template

  test "render templates" do
    assert String.contains?(
             render_template(
               DrabTestApp.Endpoint,
               "modal.alert.button.ok.html.eex",
               label: "MYLABEL"
             ),
             "MYLABEL"
           )

    assert String.contains?(
             render_template(
               DrabTestApp.Endpoint,
               "modal.alert.button.cancel.html.eex",
               label: "MYLABEL"
             ),
             "MYLABEL"
           )

    assert String.contains?(
             render_template(
               DrabTestApp.Endpoint,
               "modal.alert.bootstrap3.html.eex",
               title: "TITLE",
               class: "CLASS",
               body: "BODY",
               buttons: "buttons html",
               id: "id"
             ),
             "TITLE"
           )
  end
end
