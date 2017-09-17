defmodule DrabTestApp.LiveCommander do
  @moduledoc false

  use Drab.Commander, modules: [Drab.Live, Drab.Element]
  onload :page_loaded

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)
  end

  def update_both(socket, _) do
    poke socket, users: ["Mieczysław", "Andżelika", "Brajanek"], count: 3, color: "#66FFFF"
  end

  def update_count(socket, _) do
    poke socket, count: 3
  end

  def update_list(socket, _) do
    poke socket, users: ["Mieczysław", "Andżelika", "Brajanek"]
  end

  def update_in_partial1(socket, _) do
    poke socket, "partial1.html", in_partial: "updated partial 1", color: "#66FFFF", link: "https://tg.pl/drab"
  end

  def update_in_partial2(socket, _) do
    poke socket,  DrabTestApp.Live2View, "partial2.html", in_partial: "updated partial 2", color: "#FF6666", link: "https://tg.pl/drab/live"
  end

  def update_in_partial2_bad(socket, _) do
    poke socket, "partial2.html", in_partial: "updated partial 2", color: "#FF6666", link: "https://tg.pl/drab/live"
  end

  def update_in_partial3(socket, _) do
    poke socket, "partial3.html", in_partial: "updated partial 3", link: "https://tg.pl/"
  end

  def update_in_main_partial(socket, _) do
    poke socket, color: "#aabbcc"
  end

  def update_form(socket, sender) do
    poke socket, out: sender.params
  end

  def update_mini(socket, sender) do
    IO.inspect sender
    # poke socket, class1: "btn", class2: "btn-warning",
    #   hidden: !peek(socket, :hidden), list: [1,2,3], color: "red"
    poke(socket, link: "<i>dupa</i>", count: if(peek(socket, :count) == 42, do: 66, else: 42), list: ["A", "<b>B</b>"])
  end

end
