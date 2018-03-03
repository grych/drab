defmodule Drab.ControllerTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Controller

  test "__drab__/0 should return the valid commander" do
    assert DrabTestApp.TestController.__drab__() == %{
             commander: DrabTestApp.TestCommander,
             controller: DrabTestApp.TestController,
             view: DrabTestApp.TestView
           }
  end
end
