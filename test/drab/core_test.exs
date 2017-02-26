defmodule Drab.CoreTest do
  use Drab.ChannelCase
  import Drab.Core

  # setup do
  #   # token = Phoenix.Token.sign(@endpoint, "user socket", "nothing")
  #   {:ok, socket} = connect(Drab.Socket, %{})

  #   {:ok, socket: socket}
  # end

  test "exec and broadcast" do
    js = "console.log('test');"
    # assert {:ok, socket} = connect(Drab.Socket, %{"a" => "b"})
    # execjs(@endpoint, js)
  end
end
