defmodule DrabTestApp.LiveCommander do
  @moduledoc false
  # import Phoenix.HTML

  use Drab.Commander, modules: [Drab.Live, Drab.Element]
  onload :page_loaded

  def page_loaded(socket) do
    poke socket, text: "set in the commander"
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

  def update_link(socket, _) do
    poke socket, link: "https://elixirforum.com"
  end

  def add_item(socket, sender) do
    items = socket |> peek(:list)
    # new_item = socket |> Drab.Query.select(:val, from: "#drab_new_item")
    new_item = sender["form"]["drab[new_item]"]
    new_list = items ++ ["#{new_item}"]
    Drab.Live.poke socket, list: new_list
  end

  def update_mini(socket, sender) do
    IO.inspect sender
    # poke socket, class1: "btn", class2: "btn-warning",
    #   hidden: !peek(socket, :hidden), list: [1,2,3], color: "red"
    # poke socket, "users.html", color: "color"
    # poke socket, color: "blue", count: 13
    # poke socket, "user.html", user: "Bravo"
    # poke socket, "partial1.html", in_partial: "updated partial 1", color: "#66FFFF", link: "https://tg.pl/drab"
    # poke socket, users: ["a", "b"] #, link: "aaaa"
    # poke socket, link: "a"
    # partial4 = render_to_string(DrabTestApp.LiveView, "partial4.html", in_partial: "in partial4",
    #   color: "#aaaabb", link: "http://tg.pl")
    # set_prop(socket, "#partial4_placeholder", innerHTML: partial4)
    IO.inspect self()
    # spawn_link fn -> loop(socket) end
    spawn_link fn ->
      for _ <- 1..1000 do
        IO.inspect self()
        Process.sleep 1000
      end
    end
    Process.sleep 100000
    # poke socket, users: ["Stefan", "Marian"], user: "Zdzicha"
    poke(socket, in_partial: "in_partial after") |> IO.inspect()
    peek(socket, :in_partial) |> IO.inspect()
  end

  # defp loop(socket) do
  #   IO.inspect self()
  #   IO.inspect socket
  #   Process.sleep 5000
  #   loop(socket)
  # end

end
