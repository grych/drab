defmodule DrabTestApp.CoreTest do
  use DrabTestApp.AcceptanceCase, async: true

  test "main page", %{session: session} do
    out =
      session
      |> visit("/tests/core")
      |> find(Query.css("#page_loaded_indicator"))
      |> click(Query.button("Core1"))
      # |> all(Query.css("#core1_out"))
      # |> List.first
      # |> Element.text

    assert out == "Drab Tests"
  end
end

