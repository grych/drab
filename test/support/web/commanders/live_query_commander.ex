defmodule DrabTestApp.LiveQueryCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Live, Drab.Query]
  onload :page_loaded

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
    # this is because we do not include jQuery to globals in the brunch-config.js
    exec_js! socket, "window.$ = jQuery"
  end

end
