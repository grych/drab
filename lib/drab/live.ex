defmodule Drab.Live do
  @moduledoc false

  use DrabModule
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  def transform_payload(payload) do
    # decrypt assigns
    # TODO: maybe better to do it on demand, on poke/peek?
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
    # assigns_keys = Enum.map(assigns, fn {k, _v} -> k end) |> Enum.uniq()

    current_assigns = socket.assigns.__ampere_assigns
    assigns_to_update = Map.new(assigns)
    assigns_to_update_keys = Map.keys(assigns_to_update)

    view = socket.assigns.__controller.__drab__().view
    app_module = Drab.Config.app_module()
    router_helpers = Module.concat(app_module, Router.Helpers)
    error_helpers = Module.concat(app_module, ErrorHelpers)
    gettext = Module.concat(app_module, Gettext)

    # class = "<%= @class1 %>" class2='<%= @class2 %>' class3 = <%= @class1 %>

    # amperes of attributes contains more hashes, space separated
    amperes = socket.assigns.__amperes 
      |> Enum.map(&String.split/1)
      |> List.flatten()
      |> Enum.uniq()

    # construct the javascript for update the innerHTML of amperes
    injected_updates = for ampere_hash <- amperes do
      case Drab.Live.Cache.get(ampere_hash) do
        {:ampere, expr, assigns_in_expr} ->
          # change only if poked assign exist in this ampere
          #TODO: stay DRY
          if has_common?(assigns_in_expr, assigns_to_update_keys) do
            {safe, _assigns} = expr_with_imports(expr, view, router_helpers, error_helpers, gettext)
              |> Code.eval_quoted([assigns: assigns_for_expr(assigns_to_update, assigns_in_expr, current_assigns)])

            selector = "[drab-expr='#{ampere_hash}']"
            safe_js = safe_to_encoded_js(safe)
            "document.querySelectorAll(\"#{selector}\").forEach(function(n) {n.innerHTML = #{safe_js}})"
          else
            nil
          end
        {:attributed, expr, assigns_in_expr, attribute} ->
          if has_common?(assigns_in_expr, assigns_to_update_keys) do
            {safe, _assigns} = expr_with_imports(expr, view, router_helpers, error_helpers, gettext)
              |> Code.eval_quoted([assigns: assigns_for_expr(assigns_to_update, assigns_in_expr, current_assigns)])

            selector = "[drab-expr~='#{ampere_hash}']"
            safe_js = safe_to_encoded_js(safe)
            "document.querySelectorAll(\"#{selector}\").forEach(function(n) {n.setAttribute('#{attribute}', #{safe_js})})"
          else
            nil
          end
        _ -> raise "Ampere \"#{ampere_hash}\" can't be found in Drab Cache"
      end
      # {:ampere, expr, assigns_in_expr} = Drab.Live.Cache.get(ampere_hash)
    end |> Enum.filter(fn x -> x end)

      # for {assigns_in_expr, exprs} <- socket.assigns.__amperes["injected"], 
      #     %{"id" => id, "drab_expr" => drab_expr_hash} <- exprs do

      #   expr = Drab.Live.Cache.get(drab_expr_hash)
      #   {safe, _assigns} = expr_with_imports(hash, view, router_helpers, error_helpers, gettext)
      #     |> Code.eval_quoted([assigns: assigns_for_expr(assigns_to_update, assigns_in_expr, current_assigns)])

      #   "document.getElementById('#{id}').innerHTML = #{safe_to_encoded_js(safe)}"
      # end 

    #TODO: group updates on one node
    attributed_updates = []
      # for {drab_id, assns_exprs} <- socket.assigns.__amperes["attributed"], 
      #     {assigns_in_expr, exprs} <- assns_exprs, 
      #     %{"attribute" => attribute, "drab_expr" => drab_expr_hash} <- exprs do

      #   {safe, _assigns} = expr_with_imports(drab_expr_hash, view, router_helpers, error_helpers, gettext)
      #     |> Code.eval_quoted([assigns: assigns_for_expr(assigns_to_update, assigns_in_expr, current_assigns)])

      #   "document.querySelector(\"[drab-expr='#{drab_id}']\").setAttribute('#{attribute}', #{safe_to_encoded_js(safe)})"
      # end

    changes_assigns_js = changed_assigns_js_list(assigns_to_update)
    ampere_updates = (changes_assigns_js ++ injected_updates ++ attributed_updates) |> Enum.uniq()
      
    {:ok, _} = Drab.Core.exec_js(socket, ampere_updates |> Enum.join(";"))

    assigns_to_update = for {k, v} <- assigns_to_update, into: %{}, do: {Atom.to_string(k), v}
    updated_assigns = Map.merge(current_assigns, assigns_to_update)

    Phoenix.Socket.assign(socket, :__ampere_assigns, updated_assigns)
  end

  defp has_common?(lista, listb) do
    if Enum.find(lista, fn xa -> Enum.find(listb, fn xb -> xa == xb end) end), do: true, else: false
  end

  defp expr_with_imports(expr, view, router_helpers, error_helpers, gettext) do
    #TODO: find it in the web.ex
    # Find corresponding View
    quote do 
      import unquote(view)
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]
      use Phoenix.HTML
      import unquote(router_helpers)
      import unquote(error_helpers)
      import unquote(gettext)
      unquote(expr)
    end    
  end

  # defp find_amperes_by_assigns(amperes, assigns_keys) do
  #   #       |> Enum.filter(fn {k, _v} -> String.contains?(k, "class1") end)
  #   filtered = for assign <- assigns_keys, {k, v} <- amperes, String.contains?(k, Atom.to_string(assign)), into: %{} do
  #     {k, v}
  #   end
  #   for {assigns, amperes} <- filtered, ampere <- amperes, do: Map.merge(%{"assigns" => assigns}, ampere)
  # end

  #TODO: refactor, not very efficient
  defp assigns_for_expr(assigns_in_poke, assigns_in_expr, assigns_in_page) do
    # assigns_in_expr = String.split(assigns_in_expr) |> Enum.map(&String.to_existing_atom/1)
    missing_keys = assigns_in_expr -- Map.keys(assigns_in_poke)
    assigns_in_page = for {k, v} <- assigns_in_page, into: %{}, do: {String.to_existing_atom(k), v}
    stored_assigns = Enum.filter(assigns_in_page, fn {k, _} -> Enum.member?(missing_keys, k) end) |> Map.new()
    Map.merge(stored_assigns, assigns_in_poke) |> Map.to_list()
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
