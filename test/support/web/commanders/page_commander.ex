defmodule DrabTestApp.PageCommander do
  use Drab.Commander
  onload :page_loaded

  def page_loaded(socket) do
    socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded<button id='core1_button' drab-click='core1_click'>Core1</button></h3>", after: "#begin")
  end

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Drab.Core.execjs(socket, "$('#core1_out').html('core1')")
  end

end
