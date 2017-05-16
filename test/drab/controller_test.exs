defmodule Drab.ControllerTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Controller

  defmodule TestController do
    use Drab.Controller
  end

  test "__drab__/0 should return the valid commander" do
    assert TestController.__drab__() == %{commander: Drab.ControllerTest.TestCommander, 
                                         controller: Drab.ControllerTest.TestController,
                                         view:       Drab.ControllerTest.TestView}
  end
end
