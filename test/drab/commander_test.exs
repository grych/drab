defmodule Drab.CommanderTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Commander

  defmodule TestCommander do
    use Drab.Commander, modules: [Drab.Query]
    onload(:onload_function)
  end

  test "__drab__/0 should return the valid config" do
    assert TestCommander.__drab__() == %Drab.Commander.Config{
             commander: Drab.CommanderTest.TestCommander,
             controller: Drab.CommanderTest.TestController,
             view: Drab.CommanderTest.TestView,
             onload: :onload_function,
             modules: [Drab.Query]
           }
  end
end
