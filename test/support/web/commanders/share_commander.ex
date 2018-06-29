defmodule DrabTestApp.ShareCommander do
  @moduledoc false

  use Drab.Commander
  onload(:page_loaded)

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
  end

  def not_defined_handler(_, _) do
  end

  defhandler defined_handler(socket, _sender) do
    set_prop(socket, ".spaceholder1", innerText: "changed globally")
    poke(socket, text: "set globally", bgcolor: "grey", color: "white")
  end

  defhandler peek_text(socket, sender) do
    set_prop(socket, this(sender), innerText: peek(socket, :text) || "--- nil ---")
  end
end
