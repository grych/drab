defmodule DrabTest do
  use ExUnit.Case, ascync: true
  doctest Drab

  test "config" do
    assert Drab.config[:disable_controls_while_processing] == true
    assert Drab.config[:events_to_disable_while_processing] == ["click"]
    assert Drab.config[:disable_controls_when_disconnected] == true
    assert Drab.config[:socket] == "/drab/socket"
    assert Drab.config[:drab_store_storage] == :session_storage
  end


end
