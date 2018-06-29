defmodule DrabTestApp.Shared1Commander do
  @moduledoc false

  use Drab.Commander
  onload(:page_loaded)
  onconnect(:connected)
  before_handler(:before_handler)
  after_handler(:after_handler)

  public(:button_clicked)

  def button_clicked(socket, sender, arg \\ "outside") do
    # IO.inspect(socket)
    # IO.inspect this_commander(sender)
    set_prop(socket, this_commander(sender) <> " .spaceholder1", innerText: "changed")

    poke(
      socket,
      text: "changed in shared commander, " <> arg,
      bgcolor: "#77dddd",
      color: "#990000"
    )
  end

  defhandler peek_text(socket, sender, _) do
    set_prop(socket, this(sender), innerText: peek!(socket, :text) || "--- nil ---")
  end

  def page_loaded(socket) do
    set_prop(socket, "#shared1_onload", innerText: "set in onload")
  end

  def connected(socket) do
    set_prop(socket, "#shared1_onconnect", innerText: "set in onconnect")
  end

  def before_handler(socket, sender) do
    set_prop(
      socket,
      this_commander(sender) <> " .shared1_before_handler",
      innerText: "set in before_handler"
    )

    poke(socket, before1: "poke - before")
    true
  end

  def after_handler(socket, sender, _retval) do
    set_prop(
      socket,
      this_commander(sender) <> " .shared1_after_handler",
      innerText: "set in after_handler"
    )

    poke(socket, after1: "poke - after")
  end
end
