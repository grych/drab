defmodule DrabTestApp.Shared1Commander do
  @moduledoc false

  use Drab.Commander
  # onload(:page_loaded)
  public(:button_clicked)

  def button_clicked(socket, sender) do
    IO.inspect(socket)
    set_prop(socket, this_commander(sender) <> " .spaceholder1", innerText: "changed")
    poke(socket, text: "changed in commander")
  end

  # def page_loaded(socket) do
  #   DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
  #   DrabTestApp.IntegrationCase.add_pid(socket)
  # end
end
