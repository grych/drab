defmodule DrabTest do
  use ExUnit.Case, ascync: true
  doctest Drab

  test "config" do
    assert Drab.config[:disable_controls_while_processing] == true
    assert Drab.config[:events_to_disable_while_processing] == ["click"]
    assert Drab.config[:disable_controls_when_disconnected] == true
    assert Drab.config[:socket] == "/socket"
    assert Drab.config[:drab_store_storage] == :session_storage
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

    def function() do
      :ok
    end
  end

  
end
