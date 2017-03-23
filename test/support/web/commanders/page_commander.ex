defmodule DrabTestApp.PageCommander do
  use Drab.Commander
  onload :page_loaded

  def page_loaded(socket) do
    socket |> Drab.Query.update(:text, set: "Page Loaded", on: "#page_loaded_indicator")
  end

  ### Drab.Core ###
  def core1_click(socket, _sender) do
    Drab.Core.execjs(socket, "$('#core1_out').html('core1')")
  end

end
