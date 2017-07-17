defmodule DrabTestApp.PageCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Waiter, Drab.Query, Drab.Element, Drab.Live]
  
  
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
    # socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)

    s1 = get_session(socket, :test_session_value1) |> Drab.Core.encode_js()
    s2 = get_session(socket, :test_session_value2) |> Drab.Core.encode_js()
    exec_js! socket, "var n = document.getElementById('test_session_value1'); if (n) n.innerText = #{s1}"
    exec_js! socket, "var n = document.getElementById('test_session_value2'); if (n) n.innerText = #{s2}"

    # socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value1), on: "#test_session_value1")
    # socket |> Drab.Query.update(:text, set: get_session(socket, :test_session_value2), on: "#test_session_value2")

    # p = inspect(socket.assigns.__drab_pid)
    # pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")
    # socket |> Drab.Query.update(:text, set: pid_string, on: "#drab_pid")

    # counter is to test load&connect order
    put_store(socket, :counter, get_store(socket, :counter, 0) + 1)
    s = get_store(socket, :counter) |>  Drab.Core.encode_js()
    exec_js! socket, "var n = document.getElementById('onload_counter'); if (n) n.innerText = #{s}"
    # socket |> Drab.Query.update(:text, set: get_store(socket, :counter), on: "#onload_counter")
    # exec_js! socket, "document.getElementById('onload_counter').innerText = '" + get_store(socket, :counter) + "'"    
  end

  def page_connected(socket) do
    put_store(socket, :counter, get_store(socket, :counter, 0) + 1)
    s = get_store(socket, :counter) |>  Drab.Core.encode_js()
    exec_js! socket, "var n = document.getElementById('onconnect_counter'); if (n) n.innerText = #{s}"
    # socket |> Drab.Query.update(:text, set: get_store(socket, :counter), on: "#onconnect_counter")
  end

  #TODO: find a way to test page disconnect

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Process.sleep 500 # emulate some longer work, to test if tester waits for a button to be enabled 
    {:ok, _} = Drab.Core.exec_js(socket, "document.getElementById('core1_out').innerHTML = 'core1'")
    # the return value is passed to `after_handler`
    42
  end

  def core2_click(socket, _sender) do
    {:ok, _} = Drab.Core.broadcast_js(socket, "document.getElementById('core2_out').innerHTML = 'core2'")
    # Drab.Core.broadcast_js(socket, "$('#core2_out').html('core2')")
  end

  def core3_click(socket, _sender) do
    ### this will not be executed, as before handler prevents it
    {:ok, _} = Drab.Core.exec_js(socket, "document.getElementById('core3_out').innerHTML = 'core3'")
    # {:ok, _} = Drab.Core.exec_js(socket, "$('#core3_out').html('core3')")
    put_store(socket, :should_never_be_assigned, true)
  end

  def set_store_click(socket, _sender) do
    Drab.Core.put_store(socket, :test_store_value, "test store value")  
  end

  def get_store_click(socket, _sender) do
    s = get_store(socket, :test_store_value) |>  Drab.Core.encode_js()
    exec_js! socket, "var n = document.getElementById('store1_out'); if (n) n.innerText = #{s}"
    # socket |> Drab.Query.update(:text, set: get_store(socket, :test_store_value), on: "#store1_out")
  end


  def start_waiter(socket, _sender) do
    exec_js! socket, "document.getElementById('waiter_wrapper').innerHTML = '<button>Wait for click</button>'"
    # socket 
    #   |> delete(from: "#waiter_wrapper")
    #   |> insert("<button>Wait for click</button>", append: "#waiter_wrapper")
    answer = waiter(socket) do
      on "#waiter_wrapper button", "click", fn(_sender) ->
        "button clicked"
      end
      on_timeout 1000, fn ->
        "timeout"
      end
    end
    exec_js! socket, "document.getElementById('waiter_wrapper').innerHTML = ''"
    exec_js! socket, "document.getElementById('waiter_out_div').innerText = #{answer |> Drab.Core.encode_js()}"

    # socket 
    #   |> delete(from: "#waiter_wrapper")
    #   |> update(:text, set: answer, on: "#waiter_out_div")
  end
end
