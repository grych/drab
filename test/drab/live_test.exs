defmodule Drab.LiveTest do
  use ExUnit.Case, ascync: true
  # doctest Drab.Live, except: [:moduledoc] #does not work

  test "comment should not be rendered as Drab" do
    html = Phoenix.View.render_to_string(DrabTestApp.LiveView, "comment.html", assign: "42")
    assert String.contains?(html, "<!--42-->")
    refute String.contains?(html, "drab-ampere=")
  end

  describe "Drab.Live non-compilable cases" do
    test "with restricted words as assigns" do
      reserved_words = "<html><%= @using_assigns %></html>"
      assert_raise EEx.SyntaxError, fn ->
        EEx.compile_string(reserved_words, engine: Drab.Live.EExEngine, file: "path.html.drab")
      end
    end

    test "not allowed property" do
      wrong_property = """
      <html>
        <div @property="not allowed <%= @assign %>">
      </html>
      """
      assert_raise EEx.SyntaxError, fn ->
        EEx.compile_string(wrong_property, engine: Drab.Live.EExEngine, file: "path.html.drab")
      end
    end

    test "not allowed property 2" do
      wrong_property = """
      <html>
        <div @property="<%= @assign %><%= @assign2 %>">
      </html>
      """
      assert_raise EEx.SyntaxError, fn ->
        EEx.compile_string(wrong_property, engine: Drab.Live.EExEngine, file: "path.html.drab")
      end
    end

    test "not allowed property 3" do
      wrong_property = """
      <html>
        <div @property="<%= @assign %>">
      </html>
      """
      assert_raise EEx.SyntaxError, fn ->
        EEx.compile_string(wrong_property, engine: Drab.Live.EExEngine, file: "path.html.drab")
      end
    end

    test "not allowed property 4" do
      wrong_property = """
      <html>
        <div @property='<%= @assign %>'>
      </html>
      """
      assert_raise EEx.SyntaxError, fn ->
        EEx.compile_string(wrong_property, engine: Drab.Live.EExEngine, file: "path.html.drab")
      end
    end
  end
end
