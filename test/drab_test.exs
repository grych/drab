defmodule DrabTest do
  @moduledoc false
  
  use ExUnit.Case, ascync: true
  doctest Drab

  test "config" do
    assert Drab.Config.get(:disable_controls_while_processing) == true
    assert Drab.Config.get(:events_to_disable_while_processing) == ["click"]
    assert Drab.Config.get(:disable_controls_when_disconnected) == true
    assert Drab.Config.get(:socket) == "/socket"
    assert Drab.Config.get(:drab_store_storage) == :session_storage
  end

  describe "prerequisites" do
    test "modules" do
      assert Drab.all_modules_for([]) == [Drab.Core]
      assert Drab.all_modules_for([Drab.Query]) == [Drab.Core, Drab.Query]
      assert Drab.all_modules_for([Drab.Live]) == [Drab.Core, Drab.Live]
      assert Drab.all_modules_for([Drab.Waiter]) == [Drab.Core, Drab.Waiter]
      assert Drab.all_modules_for([Drab.Modal]) == [Drab.Core, Drab.Query, Drab.Modal]
      assert Drab.all_modules_for([Drab.Query, Drab.Live]) == [Drab.Core, Drab.Live, Drab.Query]
      assert Drab.all_modules_for([Drab.Modal, Drab.Live]) == [Drab.Core, Drab.Live, Drab.Query, Drab.Modal]
    end

    test "templates" do
      assert Drab.all_templates_for([]) == ["drab.core.js"]
      assert Drab.all_templates_for([Drab.Query]) == ["drab.core.js", "drab.events.js", "drab.query.js"]
      assert Drab.all_templates_for([Drab.Live]) == ["drab.core.js", "drab.events.js", "drab.live.js"]
      assert Drab.all_templates_for([Drab.Waiter]) == ["drab.core.js", "drab.events.js", "drab.waiter.js"]
      assert Drab.all_templates_for([Drab.Modal]) == ["drab.core.js", "drab.events.js", "drab.query.js", "drab.modal.js"]
      assert Drab.all_templates_for([Drab.Query, Drab.Live]) == 
        ["drab.core.js", "drab.events.js", "drab.live.js", "drab.query.js"]
      assert Drab.all_templates_for([Drab.Modal, Drab.Live]) == 
        ["drab.core.js", "drab.events.js", "drab.live.js", "drab.query.js", "drab.modal.js"]
    end
  end

  describe "helpers" do
    test "callbacks_for" do
      handler_config = [{:run_before_each, []}, {:run_before_uppercase, [only: [:uppercase]]}]
      assert Drab.callbacks_for(:uppercase, handler_config) == [:run_before_each, :run_before_uppercase]
      assert Drab.callbacks_for(:lowercase, handler_config) == [:run_before_each]

      handler_config = [{:run_before_each, []}, {:run_before_uppercase, [except: [:lowercase]]}]
      assert Drab.callbacks_for(:uppercase, handler_config) == [:run_before_each, :run_before_uppercase]
      assert Drab.callbacks_for(:lowercase, handler_config) == [:run_before_each]
      assert Drab.callbacks_for(:anycase, handler_config) == [:run_before_each, :run_before_uppercase]

      assert Drab.callbacks_for(:anycase, []) == []
    end

    test "function_exists?" do
      assert Drab.function_exists?(DrabTest, "function") == true
      assert Drab.function_exists?(DrabTest, "nofunction") == false
    end

    test "application config" do
      assert Drab.Config.app_name() == :drab
      assert Drab.Config.endpoint() == DrabTestApp.Endpoint
    end

    def function() do
      :ok
    end
  end

  
end
