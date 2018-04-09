defmodule DrabTestApp.Shared1Commander do
  @moduledoc false

  use Drab.Commander
  # onload(:page_loaded)
  public(:button_clicked)

  def button_clicked(socket, sender, arg \\ "outside") do
    # IO.inspect(socket)
    set_prop(socket, this_commander(sender) <> " .spaceholder1", innerText: "changed")
    poke(socket, text: "changed in shared commander, " <> arg, bgcolor: "#77dddd", color: "#990000")
  end

  defhandler peek_text(socket, sender, _) do
    set_prop(socket, this(sender), innerText: peek(socket, :text) || "--- nil ---")
  end
  # def page_loaded(socket) do
  #   DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
  #   DrabTestApp.IntegrationCase.add_pid(socket)
  # end
end
