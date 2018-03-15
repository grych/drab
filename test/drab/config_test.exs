defmodule Drab.ConfigTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Config

  test "controller_for" do
    assert Drab.Config.default_controller_for(DrabTestApp.SomeContext.SomeCommander) == DrabTestApp.SomeContext.SomeController
    assert Drab.Config.default_controller_for(DrabTestApp.LoneCommander) == DrabTestApp.LoneController
    assert Drab.Config.default_controller_for(DrabTestApp.PageCommander) == DrabTestApp.PageController
  end

  test "view_for" do
    assert Drab.Config.default_view_for(DrabTestApp.SomeContext.SomeCommander) == DrabTestApp.SomeContext.SomeView
    assert Drab.Config.default_view_for(DrabTestApp.LoneCommander) == DrabTestApp.LoneView
    assert Drab.Config.default_view_for(DrabTestApp.PageCommander) == DrabTestApp.PageView
  end

  test "commander_for" do
    assert Drab.Config.default_commander_for(DrabTestApp.NonexistentController) == DrabTestApp.NonexistentCommander
    assert Drab.Config.default_commander_for(DrabTestApp.LoneController) == DrabTestApp.LoneCommander
    assert Drab.Config.default_commander_for(DrabTestApp.PageController) == DrabTestApp.PageCommander
  end
end
