defmodule Drab.DrabModuleTest do
  use ExUnit.Case, ascync: true

  describe "prerequisites" do
    test "modules" do
      assert DrabModule.all_modules_for([]) == [Drab.Core]
      assert DrabModule.all_modules_for([Drab.Query]) == [Drab.Query, Drab.Core]
      assert DrabModule.all_modules_for([Drab.Live]) == [Drab.Live, Drab.Core]
      assert DrabModule.all_modules_for([Drab.Waiter]) == [Drab.Waiter, Drab.Core]
      assert DrabModule.all_modules_for([Drab.Modal]) == [Drab.Query, Drab.Modal, Drab.Core]

      assert DrabModule.all_modules_for([Drab.Query, Drab.Live]) == [
               Drab.Live,
               Drab.Query,
               Drab.Core
             ]

      assert DrabModule.all_modules_for([Drab.Modal, Drab.Live]) == [
               Drab.Live,
               Drab.Query,
               Drab.Modal,
               Drab.Core
             ]
    end

    test "templates" do
      assert DrabModule.all_templates_for([]) == ["drab.core.js", "drab.events.js"]
      assert DrabModule.all_templates_for([Drab.Query]) == ["drab.core.js", "drab.events.js"]

      assert DrabModule.all_templates_for([Drab.Live]) == [
               "drab.live.js",
               "drab.core.js",
               "drab.events.js"
             ]

      assert DrabModule.all_templates_for([Drab.Waiter]) == [
               "drab.waiter.js",
               "drab.core.js",
               "drab.events.js"
             ]

      assert DrabModule.all_templates_for([Drab.Modal]) == [
               "drab.modal.js",
               "drab.core.js",
               "drab.events.js"
             ]

      assert DrabModule.all_templates_for([Drab.Query, Drab.Live]) ==
               ["drab.live.js", "drab.core.js", "drab.events.js"]

      assert DrabModule.all_templates_for([Drab.Modal, Drab.Live]) ==
               ["drab.live.js", "drab.modal.js", "drab.core.js", "drab.events.js"]
    end
  end
end
