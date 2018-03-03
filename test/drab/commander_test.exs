defmodule Drab.CommanderTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Commander

  test "__drab__/0 should return the valid config for test commander" do
    assert DrabTestApp.TestCommander.__drab__() == %Drab.Commander.Config{
             commander: DrabTestApp.TestCommander,
             controller: DrabTestApp.TestController,
             view: nil, # because view does not exist
             onload: :onload_function,
             modules: [Drab.Query]
           }
  end

  test "__drab__/0 should return the valid config for page commander" do
    assert DrabTestApp.PageCommander.__drab__() == %Drab.Commander.Config{
             access_session: [:test_session_value1],
             after_handler: [after_all: [], after_most: [except: [:core3_click]]],
             before_handler: [before_all: [], cancel_handler: [only: [:core3_click]]],
             broadcasting: :same_path,
             commander: DrabTestApp.PageCommander,
             controller: DrabTestApp.PageController,
             modules: [Drab.Waiter, Drab.Query, Drab.Element, Drab.Live],
             onconnect: :page_connected,
             ondisconnect: nil,
             onload: :page_loaded,
             public_handlers: [],
             view: DrabTestApp.PageView
           }
  end

  test "__drab__/0 should return the valid config for lone commander" do
    %Drab.Commander.Config{
      access_session: [],
      after_handler: [],
      before_handler: [check_permissions: []],
      broadcasting: :same_path,
      commander: DrabTestApp.LoneCommander,
      controller: nil,
      modules: [Drab.Live, Drab.Element],
      public_handlers: [:lone_handler]
    }
  end
end
