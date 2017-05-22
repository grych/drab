defmodule DrabTestApp.LiveCommander do
  @moduledoc false
  
  use Drab.Commander, modules: [Drab.Live]
  # must insert view functions
  # use DrabTestApp.Web, :view

  onload :page_loaded

  def page_loaded(socket) do
    js = """
      var begin = document.getElementById("begin")
      var txt = document.createTextNode("Page Loaded")
      var elem = document.createElement("h3")
      elem.appendChild(txt)
      elem.setAttribute("id", "page_loaded_indicator");
      begin.parentNode.insertBefore(elem, begin.nextElementSibling)
      """
    {:ok, _} = exec_js(socket, js)

    p = inspect(socket.assigns.__drab_pid)
    pid_string = Regex.named_captures(~r/#PID<(?<pid>.*)>/, p) |> Map.get("pid")
    js = """
      var pid = document.getElementById("drab_pid")
      var txt = document.createTextNode("#{pid_string}")
      pid.appendChild(txt)
      """
    {:ok, _} = exec_js(socket, js)

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
    push socket, users: ["Zdzisław", "Andżelika", "Brajanek"]
    # push socket, user: "dupa"
    # push socket, count: 42
  end

  def update_mini(socket, _) do
    push socket, list: ["Zdzisław", "Andżelika", "Brajanek"]
  end

  defp push2(socket, assigns) do
    assigns_string = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq() |> Enum.sort() |> Enum.join(" ")
    js = """
      var spans = document.querySelectorAll("[drab-assigns='#{assigns_string}']")
      var ret = []
      for (var i = 0; i < spans.length; ++i) {
        span = spans[i]
        ret.push({
          id:         span.getAttribute("id"),
          drab_expr:  span.getAttribute("drab-expr")
        })
      }
      ret
      """

    # IO.puts js
    {:ok, exprs} = Drab.Core.exec_js(socket, js)
    # IO.inspect(exprs)

    updates = Enum.map(exprs, fn %{"id" => id, "drab_expr" => drab_expr} -> 
      # import DrabTestApp.LiveView, only: [dupa: 1]
      # IO.inspect Drab.Live.Crypto.decode(drab_expr)
      decoded = Drab.Live.Crypto.decode(drab_expr)
      #TODO: import dynamically
      expr = quote do 
        import DrabTestApp.LiveView
        unquote(decoded)
      end
      {html, _assigns} = Code.eval_quoted(expr, [assigns: assigns])
      IO.inspect html
      # js = """
      #   var spans = document.querySelectorAll("[drab-assigns='#{assigns_string}']")
      #   spans.forEach(function(span){
      #     span.innerHTML = "#{safe_to_string(html) |>  String.replace("\n", " ")}"
      #   })
      #   """
      # IO.puts(js)
      # {:ok, _} = Drab.Core.exec_js(socket, js)

      # %{"id" => id, "drab_expr" => }
      # IO.inspect html
      """
      document.getElementById('#{id}').innerHTML = "#{safe_to_string(html) |>  String.replace("\n", " ")}"
      """

    end)
    # IO.inspect updates
    {:ok, _} = Drab.Core.exec_js(socket, Enum.join(updates, ";"))
    # IO.inspect(exprs)
  end  

  defp push(socket, assigns) do
    # assigns_string = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq() |> Enum.sort() |> Enum.join(" ")
    # js = """
    #   var spans = document.querySelectorAll("[drab-assigns='#{assigns_string}']")
    #   var ret = []
    #   for (var i = 0; i < spans.length; ++i) {
    #     span = spans[i]
    #     ret.push({
    #       id:         span.getAttribute("id"),
    #       drab_expr:  span.getAttribute("drab-expr")
    #     })
    #   }
    #   ret
    #   """
    assigns_keys = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq()
    js = "Drab.find_amperes_by_assigns(#{Drab.Core.encode_js(assigns_keys)})"

    # IO.puts js
    {:ok, ret} = Drab.Core.exec_js(socket, js)
    # IO.inspect(ret)

    current_assigns = ret["current_assigns"] |>  Enum.map(fn({name, value}) -> 
      {String.to_existing_atom(name), Drab.Live.Crypto.decode(value)} 
    end) |> Map.new()
    amperes = ret["amperes"]
    assigns = Map.new(assigns)

    # require IEx; IEx.pry

    updates = Enum.map(amperes, fn %{"id" => id, "drab_expr" => drab_expr, "assigns" => assigns_in_expr} ->
      assigns_in_expr = String.split(assigns_in_expr) |> Enum.map(&String.to_existing_atom/1)
      missing_keys = assigns_in_expr -- Map.keys(assigns)
      additional_assigns = Enum.filter(current_assigns, fn {k, _} -> Enum.member?(missing_keys, k) end) |> Map.new()
      assigns_for_expr = Map.merge(additional_assigns, assigns)
      if !assigns_for_expr[:count] do
        require IEx; IEx.pry
      end

      decoded = Drab.Live.Crypto.decode(drab_expr)
      #TODO: import dynamically
      expr = quote do 
        import DrabTestApp.LiveView
        unquote(decoded)
      end
      IO.inspect assigns_for_expr
      {safe, _assigns} = Code.eval_quoted(expr, [assigns: Map.to_list(assigns_for_expr)])
      # case safe do
      #   {:safe, html} ->
      #     # IO.inspect html
      #     "document.getElementById('#{id}').innerHTML = #{safe_to_string(html) |>  Drab.Core.encode_js()}"
      #   # TODO: this is a bad hack, sometimes expr returns list. Why? Shouldn't it be only safe html?
      #   _ -> ""
      # end
      "document.getElementById('#{id}').innerHTML = #{safe_to_string(safe) |>  Drab.Core.encode_js()}"
    end)
    IO.inspect updates
    {:ok, _} = Drab.Core.exec_js(socket, Enum.join(updates, ";"))
  end


  defp safe_to_string(list) when is_list(list), do: Enum.map(list, &safe_to_string/1) |> Enum.join("")
  defp safe_to_string({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp safe_to_string(safe), do: to_string(safe)

end
