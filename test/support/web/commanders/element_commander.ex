defmodule DrabTestApp.ElementCommander do
  @moduledoc false

  use Drab.Commander, modules: [Drab.Element]
  onload(:page_loaded)

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
  end

  def inner_outer_clicked(socket, _) do
    set_prop socket, "#inner_outer_out", innerText: "inner outer clicked"
  end

  def add_outer(socket, _) do
    button = "<button id='inner_outer_button' drab='click:inner_outer_clicked'>injected</button>"
    set_prop socket, "#inner_outer", outerHTML: button
  end
end
