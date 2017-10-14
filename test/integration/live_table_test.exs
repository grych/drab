defmodule DrabTestApp.LiveTableTest do
  import Drab.Core
  use DrabTestApp.IntegrationCase

  defp form_index do
    table_url(DrabTestApp.Endpoint, :table)
  end

  setup do
    form_index() |> navigate_to()
    find_element(:id, "page_loaded_indicator") # wait for the Drab to initialize
    [socket: drab_socket()]
  end

  @td "document.getElementById('table').querySelectorAll('tr:nth-child(1) td:nth-child(2)')[0].innerText"
  @length "document.getElementById('table').querySelectorAll('tr').length"

  describe "Drab.Live" do
    test "update users should preserve the table structure" do
      socket = drab_socket()
      assert exec_js!(socket, @length) == 4
      assert exec_js!(socket, @td) == "https://tg.pl/drab"
      click_and_wait("update_users")
      assert exec_js!(socket, @length) == 3
      assert exec_js!(socket, @td) == "https://tg.pl/drab"
    end

    test "update link should preserve the table structure" do
      socket = drab_socket()
      assert exec_js!(socket, @length) == 4
      assert exec_js!(socket, @td) == "https://tg.pl/drab"
      click_and_wait("update_link")
      assert exec_js!(socket, @length) == 4
      assert exec_js!(socket, @td) == "https://elixirforum.com"
    end
  end
end
