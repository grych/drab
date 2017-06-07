defmodule Drab.Live do
  @moduledoc false

  use DrabModule
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  def transform_payload(payload) do
    # decrypt assigns
    decrypted = for {k, v} <- payload["assigns"] || %{}, into: %{}, do: {k, Drab.Live.Crypto.decode64(v)}
    Map.merge(payload, %{"assigns" => decrypted})
  end

  def transform_socket(socket, payload) do
    # store assigns in socket as well
    socket 
    |> Phoenix.Socket.assign(:__ampere_assigns, payload["assigns"])
    |> Phoenix.Socket.assign(:__amperes, payload["amperes"])
  end

  # engine: Drab.Live.EExEngine
  def render_live(template, assigns \\ []) do
    EEx.eval_file(template, [assigns: assigns], engine: Drab.Live.EExEngine)
  end


  def peek(socket, assign) when is_binary(assign) do
    socket.assigns.__ampere_assigns[assign]
  end

  def peek(socket, assign) when is_atom(assign), do: peek(socket, Atom.to_string(assign))

  def poke(socket, assigns) do
    # first, get all amperes with any of the key
    assigns_keys = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq()

    #TODO: put amperes into socket
    js = "Drab.find_amperes_by_assigns(#{Drab.Core.encode_js(assigns_keys)})"
    {:ok, ret} = Drab.Core.exec_js(socket, js)


    # ret contains a list of amperes and current (as displayed on the page) assigns
    current_assigns = ret["current_assigns"] |>  Enum.map(fn({name, value}) -> 
      {name, Drab.Live.Crypto.decode64(value)}
    end) |> Map.new()

    amperes = ret["amperes"]
    assigns_to_change = Map.new(assigns)

    # to construct the javascript for update the innerHTML of amperes
    ampere_updates = Enum.map(amperes, fn %{"id" => id, "drab_expr" => drab_expr_hash, "assigns" => assigns_in_expr} ->
      # decoded = Drab.Live.Crypto.decode(drab_expr)
      expr = Drab.Live.Cache.get(drab_expr_hash)
      # Find corresponding View
      view = socket.assigns.__controller.__drab__().view

      #TODO: find it in the web.ex
      # import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
      # use Phoenix.HTML
      # import DrabTestApp.Router.Helpers
      # import DrabTestApp.ErrorHelpers
      # import DrabTestApp.Gettext
      router_helpers = Module.concat(Drab.Config.app_module(), Router.Helpers)
      error_helpers = Module.concat(Drab.Config.app_module(), ErrorHelpers)
      gettext = Module.concat(Drab.Config.app_module(), Gettext)
      expr = quote do 
        import unquote(view)
        import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
        use Phoenix.HTML
        import unquote(router_helpers)
        import unquote(error_helpers)
        import unquote(gettext)
        unquote(expr)
      end

      {safe, _assigns} = Code.eval_quoted(expr, 
        [assigns: assigns_for_expr(assigns_to_change, assigns_in_expr, current_assigns) |> Map.to_list()])

      [
        "document.getElementById('#{id}').innerHTML = #{safe_to_encoded_js(safe)}",
        changed_assigns_js_list(assigns_to_change)
      ]
    end) |> List.flatten() |> Enum.uniq()

    # IO.inspect ampere_updates
    {:ok, _} = Drab.Core.exec_js(socket, ampere_updates |> Enum.join(";"))

    assigns_to_change = for {k, v} <- assigns_to_change, into: %{}, do: {Atom.to_string(k), v}
    updated_assigns = Map.merge(current_assigns, assigns_to_change)

    Phoenix.Socket.assign(socket, :__ampere_assigns, updated_assigns)
  end

  defp assigns_for_expr(assigns_in_poke, assigns_in_expr, assigns_in_page) do
    assigns_in_expr = String.split(assigns_in_expr) |> Enum.map(&String.to_existing_atom/1)
    missing_keys = assigns_in_expr -- Map.keys(assigns_in_poke)
    assigns_in_page = for {k, v} <- assigns_in_page, into: %{}, do: {String.to_existing_atom(k), v}
    stored_assigns = Enum.filter(assigns_in_page, fn {k, _} -> Enum.member?(missing_keys, k) end) |> Map.new()
    Map.merge(stored_assigns, assigns_in_poke)
  end

  defp changed_assigns_js_list(assigns) do
    Enum.map(assigns, fn {k, v} -> 
      "__drab.assigns[#{Drab.Core.encode_js(k)}] = #{Drab.Live.Crypto.encode64(v) |> Drab.Core.encode_js()}" 
    end)
  end

  defp safe_to_encoded_js(safe), do: safe |> safe_to_string() |> Drab.Core.encode_js()

  defp safe_to_string(list) when is_list(list), do: Enum.map(list, &safe_to_string/1) |> Enum.join("")
  defp safe_to_string({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp safe_to_string(safe), do: to_string(safe)

end
