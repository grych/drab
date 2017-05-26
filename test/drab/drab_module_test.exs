defmodule Drab.DrabModuleTest do
  use ExUnit.Case, ascync: true

  describe "prerequisites" do
    test "modules" do
      assert DrabModule.all_modules_for([]) == [Drab.Core]
      assert DrabModule.all_modules_for([Drab.Query]) == [Drab.Core, Drab.Query]
      assert DrabModule.all_modules_for([Drab.Live]) == [Drab.Core, Drab.Live]
      assert DrabModule.all_modules_for([Drab.Waiter]) == [Drab.Core, Drab.Waiter]
      assert DrabModule.all_modules_for([Drab.Modal]) == [Drab.Core, Drab.Query, Drab.Modal]
      assert DrabModule.all_modules_for([Drab.Query, Drab.Live]) == [Drab.Core, Drab.Live, Drab.Query]
      assert DrabModule.all_modules_for([Drab.Modal, Drab.Live]) == [Drab.Core, Drab.Live, Drab.Query, Drab.Modal]
    end

    test "templates" do
      assert DrabModule.all_templates_for([]) == ["drab.core.js"]
      assert DrabModule.all_templates_for([Drab.Query]) == ["drab.core.js", "drab.events.js", "drab.query.js"]
      assert DrabModule.all_templates_for([Drab.Live]) == ["drab.core.js", "drab.events.js", "drab.live.js"]
      assert DrabModule.all_templates_for([Drab.Waiter]) == ["drab.core.js", "drab.events.js", "drab.waiter.js"]
      assert DrabModule.all_templates_for([Drab.Modal]) == ["drab.core.js", "drab.events.js", "drab.query.js", "drab.modal.js"]
      assert DrabModule.all_templates_for([Drab.Query, Drab.Live]) == 
        ["drab.core.js", "drab.events.js", "drab.live.js", "drab.query.js"]
      assert DrabModule.all_templates_for([Drab.Modal, Drab.Live]) == 
        ["drab.core.js", "drab.events.js", "drab.live.js", "drab.query.js", "drab.modal.js"]
    end
  end
end
