defmodule DrabTestApp.PageCommander do
  use Drab.Commander
  onload :page_loaded

  def page_loaded(socket) do
    socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")
  end

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Drab.Core.execjs(socket, "$('#core1_out').html('core1')")
  end

end
