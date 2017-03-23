defmodule DrabTestApp.PageCommander do
  use Drab.Commander

  onload :page_loaded

  def page_loaded(socket) do
    socket 
      |> update(:html, set: "Welcome to Phoenix+Drab!", on: "h3")
  end
end
