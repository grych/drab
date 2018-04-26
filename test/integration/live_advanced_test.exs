defmodule DrabTestApp.LiveAdvancedTest do
  import Drab.{Live, Element}
  use DrabTestApp.IntegrationCase

  defp advanced_index() do
    advanced_url(DrabTestApp.Endpoint, :advanced)
  end

  setup do
    advanced_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "Drab.Live advanced" do
    test "update the list only should work", fixture do
      poke(fixture.socket, users: ["Mirmił", "Hegemon", "Kokosz", "Kajko"])

      assert query_one!(fixture.socket, "#users_list", :innerText) == %{
               "innerText" => "Mirmił Hegemon Kajko"
             }
    end

    test "update both list and child should work", fixture do
      poke(fixture.socket, users: peek(fixture.socket, :users), excluded: "Hegemon")

      assert query_one!(fixture.socket, "#users_list", :innerText) == %{
               "innerText" => "Mirmił Kokosz"
             }

      assert query_one!(fixture.socket, "#excluded", :innerText) == %{"innerText" => "Hegemon"}
    end

    @tag capture_log: true
    test "update child should not raise", fixture do
      # Code.compiler_options(warnings_as_errors: true)
      # IO.puts("\n--> the following warning is expected:")
      # assert_raise CompileError, fn -> poke(fixture.socket, excluded: "Hegemon") end
      poke(fixture.socket, excluded: "Hegemon")

      assert query_one!(fixture.socket, "#users_list", :innerText) == %{
               "innerText" => "Mirmił Kokosz"
             }

      assert query_one!(fixture.socket, "#excluded", :innerText) == %{"innerText" => "Hegemon"}
    end
  end
end
