defmodule DrabTestApp.Shared1Commander do
  @moduledoc false

  use Drab.Commander
  # onload(:page_loaded)
  public(:button_clicked)

  def button_clicked(_socket, _) do
  end

  # def page_loaded(socket) do
  #   DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
  #   DrabTestApp.IntegrationCase.add_pid(socket)
  # end
end
