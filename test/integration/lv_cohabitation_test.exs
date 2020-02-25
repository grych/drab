defmodule DrabTestApp.LVCohabitationTest do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  # setup do
  #   index_drab() |> navigate_to()
  #   # wait for the Drab to initialize
  #   find_element(:id, "page_loaded_indicator")
  #   [socket: drab_socket()]
  # end


  describe "LV Cohabitation" do

    # Check Drab page updated by COmmander
    test "A Drab page should mutate assigns" do
      navigate_to_drab_page()
      socket = drab_socket()

      # mutate assign
      assert poke(socket, status: "initialised") == {:ok, 1}

      # Process.sleep(500)

      # check mutation
      assert peek(socket, :status) == {:ok, "initialised"}
    end

    # Check LV page rendered by Controller
    test "A LV page rendered trough a Controller should be available" do
      navigate_to_lv_page()
      assert true
    end

    # Check LV page direct render
    test "A direct rendered LV page should be available" do
      navigate_to_live_page()
      assert true
    end
  end

  # Helpers

  defp navigate_to_drab_page() do
    DrabTestApp.Endpoint
    |> cohabitation_url(:index_drab, id: 42)
    |> navigate_to()
    
    # # Drab onload is async, so wait a little bitncfor its completionxw
    # Process.sleep(500)

    find_element(:id, "page_loaded_indicator")
    find_element(:id, "muted_assign_indicator_42")
  end

  defp navigate_to_lv_page() do
    DrabTestApp.Endpoint
    |> cohabitation_url(:index_lv, id: 42)
    |> navigate_to()

    find_element(:id, "page_loaded_indicator")
    find_element(:id, "muted_assign_indicator_42")
  end

  defp navigate_to_live_page() do
    DrabTestApp.Endpoint
    |> cohabitation_live_url(DrabTestApp.LVCohabitationLive, id: 42)
    |> navigate_to()

    find_element(:id, "muted_assign_indicator_42")
  end

end
