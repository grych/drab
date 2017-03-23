defmodule DrabTestApp.UserListTest do
  use DrabTestApp.AcceptanceCase, async: true

  test "main page", %{session: session} do
    h3 =
      session
      |> visit("/")
      |> all(Query.css("h3"))
      |> List.first
      |> Element.text

    assert h3 == "Drab Tests"
  end
end
