defmodule Drab.Live do
  @moduledoc """
  Drab Module to provide a live access and update of assigns of the template, which is currently rendered and displayed
  in the browser.

  The idea is to reuse your Phoenix templates and let them live, to make a possibility to update assigns 
  on the living page, from the Elixir, without reloading the whole stuff.

  Drab.Live uses the modified EEx Engine (`Drab.Live.EExEngine`) to compile the template and indicate where assigns 
  were rendered. To enable it, rename the template you want to go live from extension `.eex` to `.drab`. Then, 
  add Drab Engine to the template engines in `config.exs`:

      config :phoenix, :template_engines,
        drab: Drab.Live.Engine

  Now you may use `peek/2` to get the assign value, and `poke/2` to modify it directly in the displayed DOM tree.
  """
  import Drab.Core
  require IEx

  use DrabModule
  @doc false
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  @doc false
  def transform_payload(payload, _state) do
    payload |> Map.put_new("value", payload["val"])
  end

  @doc false
  def transform_socket(socket, payload, state) do
    # store assigns in Drab Server
    priv = Map.merge(state.priv, %{
      __ampere_assigns: payload["__assigns"],
      __amperes: payload["__amperes"]
    })
    Drab.pid(socket) |> Drab.set_priv(priv)
    socket
  end

  # def render_live(template, assigns \\ []) do
  #   EEx.eval_file(template, [assigns: assigns], engine: Drab.Live.EExEngine)
  # end

  @doc """
  Returns the current value of the assign or `nil` if not found.

      iex> peek(socket, :count)
      42
      iex> peek(socket, :nonexistent)
      nil
  """
  #TODO: think if it is needed to sign/encrypt
  def peek(socket, assign) when is_binary(assign), do: assigns(socket)[assign]
  def peek(socket, assign) when is_atom(assign), do: peek(socket, Atom.to_string(assign))

  @doc """
  Updates the current page in the browser with new assigns.

  There are several behaviours of the function, depends where the assign is:

  * in the attribute (`<tag attr=<%= @assign %> ...>`) - updates the attribute of the given node
  * in the property (`<tag attr$=<%= @assign %> ...>`) - updates the property of the given node
  * in the script (`<script>console.log('<%= @assign %>')...`) - re-evaluate the whole script
  * in the tag (`<tag><%= @assign %></tag>`) - updates the content of the tag

  Because Drab.Live must parse the page to find out where to poke the assign, there are some limitations of usage.
  Please check it in the `Drab.Live.EExEngine` description.

  Returns untouched socket.

      iex> poke(socket, count: 42)
      %Phoenix.Socket{ ...
  """
  def poke(socket, assigns) do
    do_poke(socket, assigns, &Drab.Core.exec_js/2)
  end

  @doc """
  The same as `poke/2`, but broadcasts the changes instead of pushing it to the current browser.

  See `Drab.Commander.broadcasting/1` for broadcasting options.
  """
  def poke!(socket, assigns) do
    do_poke(socket, assigns, &Drab.Core.broadcast_js/2)
  end


  defp do_poke(socket, assigns, function) do
    #TODO: improve perfomance. Now it takes 10 ms
    # t1 = :os.system_time(:microsecond)
    # Drab.Live.Cache.get("uhezdaojrga4dk")
    # IO.inspect :os.system_time(:microsecond) - t1

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
          for {type, attr_or_prop, pattern, exprs, assigns_in_ampere} <- list do
            if Regex.match?(~r/{{{{@drab-ampere:[^@}]+@drab-expr-hash:[^@}]+}}}}/, attr_or_prop) do
              #TODO: special form, without atribute name
              # ignored for now, let's think if it needs to be covered
              # warning appears during compile-time
              nil
            else
              if has_common?(assigns_in_ampere, assigns_to_update_keys) do
                evaluated_expressions = Enum.map(exprs, fn hash -> 
                  {:expr, expr, _} = Drab.Live.Cache.get(hash)
                  new_value = eval_expr(expr, modules, updated_assigns)
                  # new_value = safe_to_string(safe)
                  # new_value = safe
                  {hash, new_value}
                end)
                new_value_of_attribute = case type do
                  # update in pattern
                  :attr -> 
                    replace_pattern(pattern, evaluated_expressions) |> encode_js()
                  :prop -> 
                    {_, new_value} = evaluated_expressions |> List.first()
                    new_value |> encode_js()
                end
                "Drab.update_#{type}(#{encode_js(selector)}, #{encode_js(attr_or_prop)}, #{new_value_of_attribute})"
              else
                nil
              end
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

    IO.inspect(update_javascripts)

    assign_updates = assign_updates_js(assigns_to_update)
    all_javascripts = (assign_updates ++ update_javascripts) |> Enum.uniq()
    # IO.inspect :os.system_time(:microsecond) - t1
    {:ok, _} = function.(socket, all_javascripts |> Enum.join(";"))
    # IO.inspect :os.system_time(:microsecond) - t1

    # Save updated assigns in the Drab Server
    assigns_to_update = for {k, v} <- assigns_to_update, into: %{} do
      {Atom.to_string(k), v}
    end
    updated_assigns = Map.merge(current_assigns, assigns_to_update)
    priv = socket |> Drab.pid() |> Drab.get_priv()
    socket |> Drab.pid() |> Drab.set_priv(%{priv | __ampere_assigns: updated_assigns})

    # t2 = :os.system_time(:microsecond)
    # IO.inspect :os.system_time(:microsecond) - t1

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
end
