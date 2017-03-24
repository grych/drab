defmodule DrabTestApp.PageCommander do
  use Drab.Commander
  onload :page_loaded
  access_session :test_session_value1

  def page_loaded(socket) do
    socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")

    socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value1), on: "#test_session_value1")
    socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value2), on: "#test_session_value2")
  end

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Process.sleep 500 # emulate some longer work, to test if tester waits for a button to be enabled 
    Drab.Core.execjs(socket, "$('#core1_out').html('core1')")
  end

  def core2_click(socket, _sender) do
    Drab.Core.broadcastjs(socket, "$('#core2_out').html('core2')")
  end

  def set_store_click(socket, _sender) do
    Drab.Core.put_store(socket, :test_store_value, "test store value")  
  end

  def get_store_click(socket, _sender) do
    socket |> Drab.Query.update(:text, set: get_store(socket, :test_store_value), on: "#store1_out")
  end
end
