defmodule Drab.Live.EExEngine do
  @moduledoc """
  This is an implementation of EEx.Engine that injects `Drab.Live` behaviour.

  It parses the template during compile-time and inject Drab markers into it. Because of this, template must be
  a proper HTML. Also, there are some rules to obey, see limitations below.

  ### Limitations

  #### Avalibility of assigns
  To make the assign avaliable within Drab, it must show up in the template with "`@assign`" format. Passing it
  to `render` in the controller is not enough.

  Also, the living assign must be inside the `<%= %>` mark. If it lives in `<% %>`, it will not be updated by
  `Drab.Live.poke/2`. This means that in the following template:

      <% local = @assign %>
      <%= local %>

  poking `@assign` will not update anything.

  #### Local variables
  Local variables are only visible in its `do...end` block. You can't use a local variable from outside the block.
  So, the following is allowed:

      <%= for user <- @users do %>
        <li><%= user %></li>
      <% end %>

  and after poking a new value of `@users`, the list will be updated.

  But the next example is not valid and will raise `undefined function` exception while trying to update an `@anything`
  assign:

      <% local = @assign1 %>
      <%= if @anything do %>
        <%= local %>
      <% end %>

  #### Attributes
  The attribute must be well defined, and you can't use the expression as an attribute name.

  The following is valid:

      <button class="btn <%= @button_class %>">
      <a href="<%= build_href(@site) %>">

  But following constructs are prohibited:

      <tag <%="attr='" <> @value <> "'"%>>
      <tag <%=build_attr(@name, @value)%>>

  The above will compile (with warnings), but it will not be correctly updated with `Drab.Live.poke`.

  The tag name can not be build with the expression.

      <<%= @tag_name %> attr=value ...>

  Nested expressions are not valid in the attribute pattern. The following is not allowed:

      <tag attribute="<%= if clause do %><%= expression %><% end %>">

  Do a flat expression instead:

      <tag attribute="<%= if clause, do: expression %>">


  #### Scripts
  Tag name must be defined in the template as `<script>`, and can't be defined with the expression.

  Nested expressions are not valid in the script pattern. The following is not allowed:

      <script>
        <%= if clause do %>
          <%= expression %>
        <% end %>>
      </script>

  Do a flat expression instead:

      <script>
        <%= if clause, do: expression %>
      </script>

  #### Properties
  Property must be defined inside the tag, using strict `@property.path.from.node=<%= expression %>` syntax.
  One property may be bound only to the one assign.
  """

  import Drab.Live.Crypto
  import Drab.Live.HTML
  use EEx.Engine
  require IEx
  require Logger

  @jsvar        "__drab"
  @drab_id      "drab-ampere"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  @doc false
  def init(opts) do
    unless Path.basename(opts[:file],  Drab.Config.drab_extension())
      |> Path.extname()
      |> String.downcase() == ".html" do
        raise EEx.SyntaxError, message: """
          Drab.Live may work only with html partials.

          Invalid extention of file: #{opts[:file]}.
          """
    end
    partial = opts[:file]
    partial_hash = hash(partial)
    Logger.info "Compiling Drab partial: #{partial} (#{partial_hash})"

    Drab.Live.Cache.start()
    Drab.Live.Cache.set(partial, partial_hash)
    Drab.Live.Cache.set(partial_hash, partial)

    buffer = "{{{{@drab-partial:#{partial_hash}}}}}"
    {:safe, buffer}
  end

  @doc false
  def handle_body({:safe, body}) do
    body = List.flatten(body)

    partial_hash = partial(body)
    # found_assigns = find_assigns(body)
    # assigns_js = found_assigns |> Enum.map(fn assign ->
    #   assign_js(partial_hash, assign)
    # end) |> script_tag()

    init_js = """
      if (typeof window.#{@jsvar} == 'undefined') {#{@jsvar} = {assigns: {}, properties: {}}};
      if (typeof #{@jsvar}.index == 'undefined') {#{@jsvar}.index = '#{partial_hash}'};
      #{@jsvar}.assigns['#{partial_hash}'] = {};
      """
    found_amperes = amperes_from_buffer({:safe, body})
    amperes_to_assigns = for {ampere_id, vals} <- found_amperes do
      ampere_values = for {gender, tag, prop_or_attr, pattern} <- vals do
        compiled =
          compiled_from_pattern(gender, pattern, tag, prop_or_attr)
          |> remove_drab_marks()
        assigns = assigns_from_pattern(pattern)
        {gender, tag, prop_or_attr, compiled, assigns}
      end
      Drab.Live.Cache.set({partial_hash, ampere_id}, ampere_values)
      for {_, _, _, _, assigns} <- ampere_values, assign <- assigns do
        {assign, ampere_id}
      end
    end
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)


    # ampere-to_assign list
    for {assign, amperes} <- amperes_to_assigns do
      Drab.Live.Cache.set({partial_hash, assign}, amperes)
    end
    found_assigns = for({assign, _} <- amperes_to_assigns, do: assign) |> Enum.uniq()

    assigns_js = found_assigns |> Enum.map(fn assign ->
      assign_js(partial_hash, assign)
    end) |> script_tag()

    # other cached stuff:
    # "expr_hash" => {:expr, "expr", [assigns]}
    # "partial_hash" => {"partial_path", [assigns]}
    # "partial_path" => {"partial_hash", [assigns]
    partial_path = Drab.Live.Cache.get(partial_hash)
    Drab.Live.Cache.set(partial_hash, {partial_path, found_assigns})
    Drab.Live.Cache.set(partial_path, {partial_hash, found_assigns})

    properies_js = for {ampere_id, vals} <- found_amperes do
      found_props = for {:prop, tag, property, pattern} <- vals do
        property_js(ampere_id, property, compiled_from_pattern(:prop, pattern, tag, property))
      end
      [
        case found_props do
          [] -> ""
          _  -> "#{@jsvar}.properties['#{ampere_id}'] = {};"
        end
        | found_props
      ]
    end |> script_tag()

    final = [
      script_tag(init_js),
      remove_drab_marks(body),
      assigns_js,
      properies_js
    ] |> List.flatten()

    {:safe, final}
  end

  @expr ~r/{{{{@drab-expr-hash:(\S+)}}}}.*{{{{\/@drab-expr-hash:\S+}}}}/Us
  defp compiled_from_pattern(:prop, pattern, tag, property) do
    case compiled_from_pattern(:other, pattern, tag, property) do
      [expr | []] when is_tuple(expr) ->
        expr
      _ ->
        raise EEx.SyntaxError, message: """
          syntax error in Drab property special form for tag: <#{tag}>, property: #{property}

          You can only combine one Elixir expression with one node property.
          Allowed:

              <tag @property=<%=expression%>>

          Prohibited:

              <tag @property="other text <%=expression%>">
              <tag @property="<%=expression1%><%=expression2%>">
          """
    end
  end
  defp compiled_from_pattern(_, pattern, _, _) do
    String.split(pattern, @expr, include_captures: true, trim: true)
    |> Enum.map(&expr_from_cache/1)
  end

  defp expr_from_cache(text) do
    #TODO: not sure
    case Regex.run(@expr, text) do
      [_, expr_hash] ->
        {:expr, buffer, expr, _} = Drab.Live.Cache.get(expr_hash)
        quote do
          tmp3 = unquote(buffer)
          unquote(expr)
        end
      nil ->
        text
    end
  end

  @doc false
  def assigns_from_pattern(pattern) do
    # do not search under nested ampered tags
    pattern = case Floki.parse(pattern) do
      {_, _, _} ->
        pattern
      list when is_list(list) ->
        list
        |> Enum.reject(&ampered_tag?/1)
        |> Floki.raw_html()
      string when is_binary(string) ->
        pattern
    end
    expressions = for [_, expr_hash] <- Regex.scan(@expr, pattern), do: expr_hash
    for expr_hash <- expressions do
      {:expr, _, _, assigns} = Drab.Live.Cache.get(expr_hash)
      assigns
    end |> List.flatten() |> Enum.uniq()
  end

  defp ampered_tag?({_, attributes, _}) do
    Enum.find(attributes, fn {attribute, _} -> attribute == @drab_id end)
  end
  defp ampered_tag?(string) when is_binary(string) do
    false
  end

  @doc false
  def handle_text({:safe, buffer}, text) do
    {:safe, quote do
      [unquote(buffer), unquote(text)]
    end}
  end

  @doc false
  def handle_text("", text) do
    handle_text({:safe, ""}, text)
  end

  # @doc false
  # def handle_end(quoted) do
  #   # do not drab anything inside the expression, all is handled by the parent
  #   # TODO: not sure
  #   remove_drab_marks(quoted)
  #   # quoted
  # end

  @doc false
  def handle_expr("", marker, expr) do
    handle_expr({:safe, ""}, marker, expr)
  end

  @doc false
  def handle_expr({:safe, buffer}, "", expr) do
    expr = Macro.prewalk(expr, &handle_assign/1)
    {:safe, quote do
      tmp2 = unquote(buffer)
      unquote(expr)
      tmp2
    end}
  end

  @doc false
  def handle_expr({:safe, buffer}, "=", expr) do
    # check if the expression is in the nodrab/1
    # to be changed to "/" mark in Elixir 1.6
    {expr, nodrab} = case expr do
      {:nodrab, _, [only_one_parameter]} -> {only_one_parameter, true}
      _ -> {expr, false}
    end
    inject_span? = not in_opened_tag?(buffer)

    line = line_from_expr(expr)
    expr = Macro.prewalk(expr, &handle_assign/1)

    found_assigns = find_assigns(expr)
    # found_assigns = shallow_find_assigns(expr)
    found_assigns? = found_assigns != []

    ampere_id = hash({buffer, expr})
    attribute = "#{@drab_id}=\"#{ampere_id}\""

    html = buffer |> to_flat_html()

    buffer = if !inject_span? && found_assigns? do
      case inject_attribute_to_last_opened(buffer, attribute) do
        {:ok, buf, _}          -> buf    # injected!
        {:already_there, _, _} -> buffer # it was already there
        {:not_found, _, _}     -> raise EEx.SyntaxError, message: """
          can't find the parent tag for an expression in line #{line}.
          """
      end
    else
      buffer
    end

    hash = hash(expr)
    # TODO: not sure
    # Drab.Live.Cache.set(hash, {:expr, buffer, remove_drab_marks(expr), found_assigns})
    Drab.Live.Cache.set(hash, {:expr, [], remove_drab_marks(expr), found_assigns})

    #TODO: REFACTOR
    attr = html |> find_attr_in_html()
    is_property = Regex.match?(~r/<\S+/s, no_tags(html)) && attr && String.starts_with?(attr, "@")
    expr = if is_property, do: encoded_expr(expr), else: to_safe(expr, line)

    span_begin = "<span #{attribute}>"
    span_end   = "</span>"

    expr_begin = "{{{{@drab-expr-hash:#{hash}}}}}"
    expr_end   = "{{{{/@drab-expr-hash:#{hash}}}}}"

    nodrab = if shallow_find_assigns(expr) == [:conn], do: true, else: nodrab
    nodrab = if found_assigns?, do: nodrab, else: true

    buf = case {inject_span?, nodrab} do
      {_, true} ->
        # do not drab expressions with @conn only, as it is readonly
        # and when marked with nodrab()
        quote do
          tmp1 = unquote(buffer)
          [tmp1, unquote(expr)]
        end
      {true, _} ->
        quote do
          tmp1 = unquote(buffer)
          [tmp1, unquote(span_begin), unquote(expr_begin), unquote(expr), unquote(expr_end), unquote(span_end)]
        end
      {false, _} ->
        quote do
          tmp1 = unquote(buffer)
          [tmp1, unquote(expr_begin), unquote(expr), unquote(expr_end)]
        end
    end

    {:safe, buf}
  end

  defp partial(body) do
    html = to_flat_html(body)
    p = Regex.run ~r/{{{{@drab-partial:([^']+)}}}}/Uis, html
    #TODO: possibly dangerous - returning nil when partial not found
    if p, do: List.last(p), else: nil
  end

  defp find_attr_in_html(html) do
    args_removed = args_removed(html)
    if String.contains?(args_removed, "=") do
      args_removed
      |> String.split("=")
      |> take_at(-2)
      |> String.split(~r/\s+/)
      |> Enum.filter(fn x -> x != "" end)
      |> List.last()
    else
      nil
    end
  end

  defp args_removed(html) do
    html
    |> String.split(~r/<\S+/s)
    |> List.last()
    |> remove_full_args()
  end

  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/s, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/s, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/s, "")
  end

  defp take_at(list, index) do
    {item, _} = List.pop_at(list, index)
    item
  end

  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/s, "")

  defp script_tag([]), do: []
  defp script_tag(js) do
    ["<script drab-script>", js, "</script>\n"]
  end

  defp assign_js(partial, assign) do
    ["#{@jsvar}.assigns['#{partial}']['#{assign}'] = '", encoded_assign(assign), "';"]
  end

  defp property_js(ampere, property, expr) do
    ["#{@jsvar}.properties['#{ampere}']['#{property}'] = ", encoded_expr(expr), ";"]
  end


  defp encoded_assign(assign) do
    assign_expr = quote @anno do
      Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(assign))
    end

    base64_encoded_expr(assign_expr)
  end

  defp base64_encoded_expr(expr) do
    quote @anno do
      Drab.Live.Crypto.encode64(unquote(expr))
    end
  end

  @doc false
  def encoded_expr(expr) do
    quote @anno do
      Drab.Core.encode_js(unquote(expr))
    end
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  # @doc false
  # defp to_safe(literal), do: to_safe(literal, @anno)

  defp to_safe(literal, _line) when is_binary(literal) or is_atom(literal) or is_number(literal) do
    Phoenix.HTML.Safe.to_iodata(literal)
  end

  defp to_safe(literal, line) when is_list(literal) do
    quote line: line, do: Phoenix.HTML.Safe.to_iodata(unquote(literal))
  end

  defp to_safe(expr, line) do
    # Keep stacktraces for protocol dispatch...
    fallback = quote line: line, do: Phoenix.HTML.Safe.to_iodata(other)

    # However ignore them for the generated clauses to avoid warnings
    quote @anno do
      case unquote(expr) do
        {:safe, data} -> data
        bin when is_binary(bin) -> Plug.HTML.html_escape(bin)
        other -> unquote(fallback)
      end
    end
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(name))
    end
  end
  defp handle_assign(arg), do: arg

  defp find_assigns(ast) do
    {_, result} = Macro.prewalk ast, [], fn node, acc ->
      case node do
        {{:., _, [{:__aliases__, _, [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, _, [_, name]} when is_atom(name) ->
          {node, [name | acc]}
        _ ->
          {node, acc}
      end
    end
    result |> Enum.uniq() |> Enum.sort()
  end

  @doc false
  def shallow_find_assigns(ast) do
    {_, assigns} = do_find(ast, [])
    Enum.uniq(assigns)
  end

  defp do_find({:safe, _}, acc) do
    {nil, acc}
  end

  defp do_find({form, meta, args}, acc) when is_atom(form) do
    {args, acc} = do_find_args(args, acc)
    {{form, meta, args}, acc}
  end

  defp do_find({form, meta, args} = ast, acc) do
    found_assign = find_assign(ast)
    {form, acc} = do_find(form, acc)
    {args, acc} = do_find_args(args, acc)
    acc = if found_assign, do: [found_assign | acc], else: acc
    {{form, meta, args}, acc}
  end

  defp do_find({left, right}, acc) do
    {left, acc} = do_find(left, acc)
    {right, acc} = do_find(right, acc)
    {{left, right}, acc}
  end

  defp do_find(list, acc) when is_list(list) do
    do_find_args(list, acc)
  end

  defp do_find(x, acc) do
    {x, acc}
  end

  defp do_find_args(args, acc) when is_atom(args) do
    {args, acc}
  end

  defp do_find_args(args, acc) when is_list(args) do
    Enum.map_reduce(args, acc, fn x, acc ->
      do_find(x, acc)
    end)
  end

  defp find_assign({{:., _, [{:__aliases__, _, [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, _, [_, name]})
    when is_atom(name), do: name
  defp find_assign(_), do: false
end
