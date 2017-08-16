defmodule DrabTestApp.PartialsCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Live, Drab.Element]
  onload :page_loaded

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)

    button = "<button drab-click='change_partial1'>Change partial1</button>"

    poke socket, live_partial1: render_to_string(DrabTestApp.LiveView, "partial1.html", in_partial: "in partial1",
      color: "#aaaabb", link: "http://tg.pl")
    poke socket, button1_placeholder: button

    insert_html(socket, "#button2_placeholder", :beforebegin, button)

    set_prop(socket, "#button3_placeholder", innerHTML: button)
  end


  def change_partial1(socket, _sender) do
    poke socket, DrabTestApp.LiveView, "partial1.html", 
      in_partial: "changed", link: "http://elixirforum.com", color: "#ff3322"
  end

end
