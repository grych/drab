defmodule Drab.LiveTest do
  use ExUnit.Case, ascync: true
  # doctest Drab.Live, except: [:moduledoc] #does not work

  test "comment should not be rendered as Drab" do
    html = Phoenix.View.render_to_string(DrabTestApp.LiveView, "comment.html", assign: "42")
    assert String.contains?(html, "<!--42-->")
    refute String.contains?(html, "drab-ampere=")
  end
end
