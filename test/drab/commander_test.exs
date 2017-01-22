defmodule Drab.CommanderTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Commander

  defmodule TestCommander do
    use Drab.Commander, onload: :onload_function, modules: [:query]
  end

  test "__drab__/0 should return the valid config" do
    assert TestCommander.__drab__() == %Drab.Config{commander: Drab.CommanderTest.TestCommander,
                                                    onload:    :onload_function,
                                                    modules: [:query]}
  end
end
