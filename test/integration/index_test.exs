defmodule DrabTestApp.IndexTest do
  use DrabTestApp.IntegrationCase

  defp page_index do
    index_url(DrabTestApp.Endpoint, :index)
  end

  test "index page" do
    page_index() |> navigate_to()
    h4 = find_element(:id, "header")
    assert visible_text(h4) == "Drab Tests"
  end
end
