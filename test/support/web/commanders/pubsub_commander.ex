defmodule DrabTestApp.PubsubCommander do
  @moduledoc false

  use Drab.Commander

  onload_init(:do_init)
  onload(:page_loaded)

  def do_init() do
    DrabTestApp.Backend.subscribe()
  end

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
  end

  def handle_info_message({DrabTestApp.Backend, [:data, :updated], result}, socket) do
    poke(socket, status: "updated", data: result )
  end
end
