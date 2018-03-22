defmodule Drab.ControllerTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Controller

  defmodule TestController do
    use Drab.Controller, commander: Drab.ControllerTest.TestCommander
  end

  defmodule TestCommander do
    use Drab.Commander, modules: [Drab.Query]
    onload(:onload_function)
  end

  test "__drab__/0 should return the valid commander" do
    assert Drab.ControllerTest.TestController.__drab__() == %{
             commander: Drab.ControllerTest.TestCommander,
             commanders: [],
             controller: Drab.ControllerTest.TestController,
             view: Drab.ControllerTest.TestView
           }
  end
end
