defmodule DrabTestApp.LVCohabitationCommander do
  @moduledoc false

  use Drab.Commander

  onload(:page_loaded)

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
  end

end
