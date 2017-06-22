defmodule Drab.Live do
  @moduledoc false
  import Drab.Core
  require IEx

  use DrabModule
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  def transform_payload(payload, _state) do
    # IO.inspect payload
    # decrypt assigns
    # TODO: maybe better to do it on demand, on poke/peek?

    # decrypted = for {k, v} <- payload["assigns"] || %{}, into: %{}, do: {k, Drab.Live.Crypto.decode64(v)}
    # Map.merge(payload, %{"assigns" => decrypted})
    #   |> Map.put_new("value", payload["val"])
    payload |> Map.put_new("value", payload["val"])
    # payload
  end

  def transform_socket(socket, payload, state) do
    # # store assigns in Drab Server
    priv = Map.merge(state.priv, %{
      __ampere_assigns: payload["__assigns"],
      __amperes: payload["__amperes"]
    })
    Drab.pid(socket) |> Drab.set_priv(priv)
    socket
  end

  # engine: Drab.Live.EExEngine
  def render_live(template, assigns \\ []) do
    EEx.eval_file(template, [assigns: assigns], engine: Drab.Live.EExEngine)
  end

  defp assigns(socket) do
    socket 
      |> Drab.pid() 
      |> Drab.get_priv() 
      |> Map.get(:__ampere_assigns)
  end

  defp amperes(socket) do
    socket 
      |> Drab.pid() 
      |> Drab.get_priv() 
      |> Map.get(:__amperes)
  end

  def peek(socket, assign) when is_binary(assign) do
    #TODO: think if it is needed to sign/encrypt
    assigns(socket)[assign]
      # |> Drab.Live.Crypto.decode64()
  end

  def peek(socket, assign) when is_atom(assign), do: peek(socket, Atom.to_string(assign))

  def poke(socket, assigns) do
    #TODO: takes milliseconds. Too long? The longest part is to create JSs
    t1 = :os.system_time(:microsecond)
    Drab.Live.Cache.get("uhezdaojrga4dk")
    IO.inspect :os.system_time(:microsecond) - t1

    current_assigns = assigns(socket)
    assigns_to_update = Enum.into(assigns, %{})
    assigns_to_update_keys = Map.keys(assigns_to_update)

    updated_assigns = current_assigns
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.merge(assigns)

    app_module = Drab.Config.app_module()
    modules = {
      socket.assigns.__controller.__drab__().view,
      Module.concat(app_module, Router.Helpers),
      Module.concat(app_module, ErrorHelpers),
      Module.concat(app_module, Gettext)
    }


    # TODO: check only amperes which contains the changed assigns
    amperes = amperes(socket)

    # construct the javascripts for update of amperes
    #TODO: group updates on one node
    update_javascripts = for ampere_hash <- amperes do
      selector = "[drab-ampere='#{ampere_hash}']"

      case Drab.Live.Cache.get(ampere_hash) do
        {:expr, expr, assigns_in_expr} ->
          # change only if poked assign exist in this ampere
          #TODO: stay DRY
          if has_common?(assigns_in_expr, assigns_to_update_keys) do
            safe = eval_expr(expr, modules, updated_assigns)
            new_value = safe_to_encoded_js(safe)

            "Drab.update_drab_span(#{encode_js(selector)}, #{new_value})"
          else
            nil
          end
        {:attribute, list} ->
          for {attribute, pattern, exprs, assigns_in_ampere} <- list do
            if has_common?(assigns_in_ampere, assigns_to_update_keys) do
              evaluated_expressions = Enum.map(exprs, fn hash -> 
                {:expr, expr, _} = Drab.Live.Cache.get(hash)
                safe = eval_expr(expr, modules, updated_assigns)
                new_value = safe_to_string(safe)
                {hash, new_value}
              end)
              new_value_of_attribute = replace_pattern(pattern, evaluated_expressions) |> encode_js()

              if Regex.match?(~r/{{{{@drab-ampere:[^@}]+@drab-expr-hash:[^@}]+}}}}/, attribute) do
                #TODO: special form, without atribute name
                # ignored for now, let's think if it needs to be covered
                # warning appears during compile-time
                nil
              else
                "Drab.update_attribute(#{encode_js(selector)}, #{encode_js(attribute)}, #{new_value_of_attribute})"
              end
            else
              nil
            end
          end
        {:script, pattern, exprs, assigns_in_ampere} -> 
          if has_common?(assigns_in_ampere, assigns_to_update_keys) do
            hash_and_value = Enum.map(exprs, fn hash ->
              {:expr, expr, _} = Drab.Live.Cache.get(hash)
              safe = eval_expr(expr, modules, updated_assigns)
              new_value = safe_to_string(safe)

              {hash, new_value}
            end)
            new_script = replace_pattern(pattern, hash_and_value) |> encode_js()
            "Drab.update_script(#{encode_js(selector)}, #{new_script})"
          else
            nil
          end
        _ -> raise "Ampere \"#{ampere_hash}\" can't be found in Drab Cache"
        # _ -> nil
      end
    end |> List.flatten() |> Enum.filter(&(&1))

    # IO.inspect(update_javascripts)

    assign_updates = assign_updates_js(assigns_to_update)
    all_javascripts = (assign_updates ++ update_javascripts) |> Enum.uniq()
    {:ok, _} = Drab.Core.exec_js(socket, all_javascripts |> Enum.join(";"))
    IO.inspect :os.system_time(:microsecond) - t1

    # Save updated assigns in the Drab Server
    assigns_to_update = for {k, v} <- assigns_to_update, into: %{} do
      {Atom.to_string(k), v}
    end
    updated_assigns = Map.merge(current_assigns, assigns_to_update)
    priv = socket |> Drab.pid() |> Drab.get_priv()
    socket |> Drab.pid() |> Drab.set_priv(%{priv | __ampere_assigns: updated_assigns})

    t2 = :os.system_time(:microsecond)
    IO.inspect t2-t1

    socket
  end

  defp replace_pattern(pattern, []), do: pattern
  defp replace_pattern(pattern, [{hash, value} | rest]) do
    new_pattern = String.replace(pattern, ~r/{{{{@drab-ampere:[^@}]+@drab-expr-hash:#{hash}}}}}/, value, global: true)
    replace_pattern(new_pattern, rest)
  end

  defp has_common?(list1, list2) do
    if Enum.find(list1, fn xa -> 
      Enum.find(list2, fn xb -> xa == xb end) 
    end), do: true, else: false
  end

  defp eval_expr(expr, modules, updated_assigns) do
    {safe, _assigns} = expr_with_imports(expr, modules)
      |> Code.eval_quoted([assigns: updated_assigns])
    safe
  end

  defp expr_with_imports(expr, modules) do
    #TODO: find it in the web.ex
    {view, router_helpers, error_helpers, gettext} = modules
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

  # #TODO: refactor, not very efficient
  # defp assigns_for_expr(assigns_in_poke, assigns_in_expr, assigns_in_page) do
  #   # assigns_in_expr = String.split(assigns_in_expr) |> Enum.map(&String.to_existing_atom/1)
  #   missing_keys = assigns_in_expr -- Map.keys(assigns_in_poke)
  #   assigns_in_page = for {k, v} <- assigns_in_page, into: %{}, do: {String.to_existing_atom(k), v}
  #   stored_assigns = Enum.filter(assigns_in_page, fn {k, _} -> Enum.member?(missing_keys, k) end) |> Map.new()
  #   Map.merge(stored_assigns, assigns_in_poke) |> Map.to_list()
  # end

  defp assign_updates_js(assigns) do
    Enum.map(assigns, fn {k, v} -> 
      "__drab.assigns[#{Drab.Core.encode_js(k)}] = #{Drab.Core.encode_js(v)}" 
    end)
  end

  defp safe_to_encoded_js(safe), do: safe |> safe_to_string() |> encode_js()

  defp safe_to_string(list) when is_list(list), do: Enum.map(list, &safe_to_string/1) |> Enum.join("")
  defp safe_to_string({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp safe_to_string(safe), do: to_string(safe)

end
