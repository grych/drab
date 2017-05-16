defmodule DrabTestApp.AmpereCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Ampere]

  onload :page_loaded

  def page_loaded(socket) do
    js = """
      var begin = document.getElementById("begin")
      var txt = document.createTextNode("Page Loaded")
      var elem = document.createElement("h3")
      elem.appendChild(txt)
      elem.setAttribute("id", "page_loaded_indicator");
      begin.parentNode.insertBefore(elem, begin.nextElementSibling)
      """
    {:ok, _} = exec_js(socket, js)

    p = inspect(socket.assigns.__drab_pid)
    pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")
    js = """
      var pid = document.getElementById("drab_pid")
      var txt = document.createTextNode("#{pid_string}")
      pid.appendChild(txt)
      """
    {:ok, _} = exec_js(socket, js)

    # socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")
    # socket |> Drab.Query.insert("<h5>Drab Broadcast Topic: #{__drab__().broadcasting |> inspect}</h5>", 
    #   after: "#page_loaded_indicator")
    # p = inspect(socket.assigns.__drab_pid)
    # pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")
    # socket |> Drab.Query.update(:text, set: pid_string, on: "#drab_pid")
  end
end
