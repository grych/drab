defmodule Drab.TemplatesTest do
  use ExUnit.Case, ascync: true
  import Drab.Templates
  doctest Drab.Templates

  test "render templates" do
    assert String.contains?(render_template("call.alert.button.ok.html.eex", [label: "MYLABEL"]), "MYLABEL")
    assert String.contains?(render_template("call.alert.button.cancel.html.eex", [label: "MYLABEL"]), "MYLABEL")
    assert String.contains?(render_template("call.alert.html.eex", 
      [title: "TITLE", class: "CLASS", body: "BODY", buttons: "buttons html"]), "TITLE")
  end


end
