defmodule DrabTestApp.LiveCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Live]
  # must insert view functions
  # use DrabTestApp.Web, :view

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
    # poke socket, count: 3
    # poke socket, user: "dupa"
    # poke socket, count: 42
  end

  def update_count(socket, _) do
    poke socket, count: 42
  end

  def update_list(socket, _) do
    poke socket, users: ["Mieczysław", "Andżelika", "Brajanek"]
    # poke socket, user: "dupa"
    # poke socket, count: 42
  end

  def update_mini(socket, _payload) do
    # list = peek(socket, :list) ++ ["Zdzisław", "Andżelika", "Brajanek"]
    # IO.inspect peek(socket, :list)
    # socket = poke socket, list: list
    # IO.inspect peek(socket, :list)
    poke socket, tag: :hr
  end

end
