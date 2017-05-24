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
    push socket, users: ["Mieczysław", "Andżelika", "Brajanek"], count: 3
    # push socket, count: 3
    # push socket, user: "dupa"
    # push socket, count: 42
  end

  def update_count(socket, _) do
    push socket, count: 42
  end

  def update_list(socket, _) do
    push socket, users: ["Mieczysław", "Andżelika", "Brajanek"]
    # push socket, user: "dupa"
    # push socket, count: 42
  end

  def update_mini(socket, _) do
    push socket, list: ["Zdzisław", "Andżelika", "Brajanek"]
  end

  defp push(socket, assigns) do
    # first, get all amperes with any of the key
    assigns_keys = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq()

    #TODO: check for ampere_assigns in socket
    js = "Drab.find_amperes_by_assigns(#{Drab.Core.encode_js(assigns_keys)})"
    {:ok, ret} = Drab.Core.exec_js(socket, js)

    # ret contains a list of amperes and current (as displayed on the page) assigns
    current_assigns = ret["current_assigns"] |>  Enum.map(fn({name, value}) -> 
      {String.to_existing_atom(name), Drab.Live.Crypto.decode(value)} 
    end) |> Map.new()

    amperes = ret["amperes"]
    assigns_to_change = Map.new(assigns)

    # to construct the javascript for update the innerHTML of amperes
    ampere_updates = Enum.map(amperes, fn %{"id" => id, "drab_expr" => drab_expr, "assigns" => assigns_in_expr} ->
      decoded = Drab.Live.Crypto.decode(drab_expr)
      #TODO: import dynamically
      expr = quote do 
        import DrabTestApp.LiveView
        unquote(decoded)
      end
      {safe, _assigns} = Code.eval_quoted(expr, 
        [assigns: assigns_for_expr(assigns_to_change, assigns_in_expr, current_assigns) |> Map.to_list()])

      [
        "document.getElementById('#{id}').innerHTML = #{safe_to_encoded_js(safe)}",
        changed_assigns_js_list(assigns_to_change)
      ]
    end) |> List.flatten() |> Enum.uniq()

    IO.inspect ampere_updates
    {:ok, _} = Drab.Core.exec_js(socket, ampere_updates |> Enum.join(";"))
  end

  defp assigns_for_expr(assigns_in_push, assigns_in_expr, assings_in_page) do
    assigns_in_expr = String.split(assigns_in_expr) |> Enum.map(&String.to_existing_atom/1)
    missing_keys = assigns_in_expr -- Map.keys(assigns_in_push)
    stored_assigns = Enum.filter(assings_in_page, fn {k, _} -> Enum.member?(missing_keys, k) end) |> Map.new()
    Map.merge(stored_assigns, assigns_in_push)
  end

  defp changed_assigns_js_list(assigns) do
    Enum.map(assigns, fn {k, v} -> 
      "__drab.assigns[#{Drab.Core.encode_js(k)}] = #{Drab.Live.Crypto.encode(v) |> Drab.Core.encode_js()}" 
    end)
  end

  defp safe_to_encoded_js(safe), do: safe |> safe_to_string() |> Drab.Core.encode_js()

  defp safe_to_string(list) when is_list(list), do: Enum.map(list, &safe_to_string/1) |> Enum.join("")
  defp safe_to_string({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp safe_to_string(safe), do: to_string(safe)

end
