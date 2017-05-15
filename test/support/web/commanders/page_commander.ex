defmodule DrabTestApp.PageCommander do
  use Drab.Commander
  
  onload :page_loaded
  onconnect :page_connected

  access_session :test_session_value1

  before_handler :before_all
  after_handler  :after_all
  before_handler :cancel_handler, only: [:core3_click]
  after_handler  :after_most, except: [:core3_click]

  def before_all(socket, _sender) do
    put_store(socket, :set_in_before_all, :before)
    true
  end

  def after_all(socket, _sender, handler_return) do
    put_store(socket, :set_in_after_all, handler_return)
  end

  def cancel_handler(_socket, _sender) do
    false
  end

  def after_most(socket, _sender, _return) do
    put_store(socket, :shouldnt_be_set_in_core3, true)
  end

  def page_loaded(socket) do
    socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")

    socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value1), on: "#test_session_value1")
    socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value2), on: "#test_session_value2")

    p = inspect(socket.assigns.__drab_pid)
    pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")

    socket |> Drab.Query.update(:text, set: pid_string, on: "#drab_pid")

    # counter is to test load&connect order
    put_store(socket, :counter, get_store(socket, :counter, 0) + 1)
    socket |> Drab.Query.update(:text, set: get_store(socket, :counter), on: "#onload_counter")
  end

  def page_connected(socket) do
    put_store(socket, :counter, get_store(socket, :counter, 0) + 1)    
    socket |> Drab.Query.update(:text, set: get_store(socket, :counter), on: "#onconnect_counter")
  end

  #TODO: find a way to test page disconnect

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Process.sleep 500 # emulate some longer work, to test if tester waits for a button to be enabled 
    {:ok, _} = Drab.Core.exec_js(socket, "$('#core1_out').html('core1')")
    # the return value is passed to `after_handler`
    42
  end

  def core2_click(socket, _sender) do
    Drab.Core.broadcast_js(socket, "$('#core2_out').html('core2')")
  end

  def core3_click(socket, _sender) do
    {:ok, _} = Drab.Core.exec_js(socket, "$('#core3_out').html('core3')")
    put_store(socket, :should_never_be_assigned, true)
  end

  def set_store_click(socket, _sender) do
    Drab.Core.put_store(socket, :test_store_value, "test store value")  
  end

  def get_store_click(socket, _sender) do
    socket |> Drab.Query.update(:text, set: get_store(socket, :test_store_value), on: "#store1_out")
  end

  ### Drab.Modal ###
  defp modal_out(socket, sender), do: select(socket, data: "modal", from: this(sender)) <> "_out"

  defp update_out(socket, sender, ret), do: 
    socket |> update(:text, set: inspect(ret), on: "##{modal_out(socket, sender)}")

  def show_modal1(socket, sender) do
    ret = socket |> alert("Title", "Message")
    update_out(socket, sender, ret) 
  end

  def show_modal2(socket, sender) do
    ret = socket |> alert("Title", "Message", timeout: 1500)
    update_out(socket, sender, ret) 
  end

  def show_modal3(socket, sender) do
    form = "Message<br><input name='first'><input id='second'>"
    ret = socket |> alert("Title", form, buttons: [ok: "OK", cancel: "CANCEL"])
    update_out(socket, sender, ret) 
  end

  def show_modal4(socket, sender) do
    ret = socket |> alert("Title", "Message", buttons: [additional: "Additional"])
    update_out(socket, sender, ret) 
  end

  def start_waiter(socket, _sender) do
    socket 
      |> delete(from: "#waiter_wrapper")
      |> insert("<button>Wait for click</button>", append: "#waiter_wrapper")
    answer = waiter(socket) do
      on "#waiter_wrapper button", "click", fn(_sender) ->
        "button clicked"
      end
      on_timeout 1000, fn ->
        "timeout"
      end
    end
    socket 
      |> delete(from: "#waiter_wrapper")
      |> update(:text, set: answer, on: "#waiter_out_div")
  end
end
