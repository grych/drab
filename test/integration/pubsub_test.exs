defmodule DrabTestApp.PubsubTest do
  import Drab.Live
  use DrabTestApp.IntegrationCase

  defp pubsub_index do
    pubsub_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    pubsub_index() |> navigate_to()
    # wait for the Drab to initialize
    find_element(:id, "page_loaded_indicator")
    [socket: drab_socket()]
  end

  describe "PubSub" do
    test "Subscribed PubSub events should trigger `handle_info_message` in the Commander" do
      socket = drab_socket()

      # Changes some data in the db, this will trigger a PubSub event
      DrabTestApp.Backend.append_element(42)

      # Above operation is async, so wait a little bit
      # for its completion before checking the result
      Process.sleep(500)

      # Check if the `handle_info_message` had changed the
      # page assigns according to the new data
      assert peek(socket, :status) == {:ok, "updated"}
      assert peek(socket, :data) == {:ok, [1, 2, 3, 42]}
    end
  end
end
