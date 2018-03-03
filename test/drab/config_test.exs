defmodule Drab.ConfigTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Config

  test "controller_for" do
    assert Drab.Config.controller_for(DrabTestApp.SomeContext.SomeCommander) == nil
    assert Drab.Config.controller_for(DrabTestApp.LoneCommander) == nil
    assert Drab.Config.controller_for(DrabTestApp.PageCommander) == DrabTestApp.PageController
  end

  test "view_for" do
    assert Drab.Config.view_for(DrabTestApp.SomeContext.SomeCommander) == nil
    assert Drab.Config.view_for(DrabTestApp.LoneCommander) == nil
    assert Drab.Config.view_for(DrabTestApp.PageCommander) == DrabTestApp.PageView
  end

  test "commander_for" do
    assert Drab.Config.commander_for(DrabTestApp.NonexistentController) == nil
    assert Drab.Config.commander_for(DrabTestApp.LoneController) == DrabTestApp.LoneCommander
    assert Drab.Config.commander_for(DrabTestApp.PageController) == DrabTestApp.PageCommander
  end
end
