defmodule DrabTestApp.LiveCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Live]
  onload :page_loaded

  def page_loaded(socket) do
    DrabTestApp.IntegrationCase.add_page_loaded_indicator(socket)
    DrabTestApp.IntegrationCase.add_pid(socket)

    # socket |> Drab.Query.insert("<h3 id='page_loaded_indicator'>Page Loaded</h3>", after: "#begin")
    # socket |> Drab.Query.insert("<h5>Drab Broadcast Topic: #{__drab__().broadcasting |> inspect}</h5>", 
    #   after: "#page_loaded_indicator")
    # p = inspect(socket.assigns.__drab_pid)
    # pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")
    # socket |> Drab.Query.update(:text, set: pid_string, on: "#drab_pid")
  end

  def update_both(socket, _) do
    poke socket, users: ["Mieczysław", "Andżelika", "Brajanek"], count: 3
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
    poke socket, "partial2.html", in_partial: "updated partial 2", color: "#FF6666", link: "https://tg.pl/drab/live"
  end

  def update_in_both_partials(socket, _) do
    poke socket, in_partial: "updated both partials", color: "#FF8000"
  end

  def update_mini(socket, sender) do
    IO.inspect sender
    poke socket, class1: "btn", class2: "btn-warning", full_class: "btn btn-danger", 
      hidden: !peek(socket, :hidden), list: [1,2,3], color: "red"
  end

end
