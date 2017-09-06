defmodule Drab.Live.EExEngine do
  @moduledoc """
  This is an implementation of EEx.Engine that injects `Drab.Live` behaviour.

  It parses the template during compile-time and inject Drab markers into it. Because of this, template must be
  a proper HTML. Also, there are some rules to obey, see limitations below.

  ### Limitations

  #### Avalibility of assigns
  To make the assign avaliable within Drab, it must show up in the template with "`@assign`" format. Passing it
  to `render` in the controller is not enough.

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

  #### Textareas
  As above, you can not use nested expressions inside the textarea tag.

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
  @special_tags ["script", "textarea"]

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

          Invalid extension of file: #{opts[:file]}.
          """
    end
    partial = opts[:file]
    partial_hash = hash(partial)
    Logger.info "Compiling Drab partial: #{partial} (#{partial_hash})"

    Drab.Live.Cache.start()
    Drab.Live.Cache.set({:partial, partial}, partial_hash)
    Drab.Live.Cache.set({:partial, partial_hash}, partial)

    buffer = ["\n<span drab-partial='#{partial_hash}'>\n"]
    start_shadow_buffer(buffer, partial_hash |> String.to_atom()) # can't leak, only in compile-time
    {:safe, buffer}
  end

  @doc false
  def handle_body({:safe, body}) do
    body = List.flatten(body)

    found_assigns = find_assigns(body)
    partial = partial(body)
    assigns_js = found_assigns |> Enum.map(fn assign ->
      assign_js(partial, assign)
    end) |> script_tag()

    init_js = """
      if (typeof window.#{@jsvar} == 'undefined') {window.#{@jsvar} = {assigns: {}}};
      window.#{@jsvar}.assigns['#{partial}'] = {};
      """
    put_shadow_buffer("\n</span>\n", partial)

    shadow = get_shadow_buffer(partial(body)) |> Floki.parse()
    Drab.Live.Cache.set({:shadow, partial(body)}, shadow)
    stop_shadow_buffer(partial(body))

    # find all the attributes
    # add to cache:
    # expression hash is alrady in cache:  hash, {:expr, expr, found_assigns}
    # drab_ampere -> {:attribute, [ { "attribute", "pattern", [ {:expr, ast, [assigns] ] } ], all_assigns_in_ampere}
    attributes = attributes_from_shadow(shadow)
    grouped_by_ampere = Enum.map(attributes, fn {attribute, pattern} ->
      # is_prop? = String.starts_with?(attribute, "@")
      {ampere_from_pattern(pattern),
        {
          :attr,
          # (if is_prop?, do: :prop, else: :attr),
          # (if is_prop?, do: String.replace(attribute, ~r/^\@/, ""), else: attribute),
          attribute,
          pattern,
          expression_hashes_from_pattern(pattern),
          assigns_from_pattern(pattern)
        }
      }
    end) |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

    for {ampere, list} <- grouped_by_ampere do
      {:attribute, existing} = Drab.Live.Cache.get(ampere) || {:attribute, []}
      Drab.Live.Cache.set(ampere, {:attribute, Enum.uniq(existing ++ list)})
    end

    # scripts, textareas
    for tag <- @special_tags, pattern <- tags_from_shadow(shadow, tag) do
      ampere = ampere_from_pattern(pattern)
      hashes = expression_hashes_from_pattern(pattern)
      assigns = assigns_from_pattern(pattern)
      Drab.Live.Cache.set(ampere, {String.to_atom(tag), pattern, hashes, assigns})
    end

    final = [
      body,
      "\n</span>\n",
      script_tag(init_js),
      assigns_js,
    ] |> List.flatten()

    #TODO: check if in the expression of attribute or script or textarea
    # there is another expression, like
    #    [[{:|, [], ["", "\n"]}],
    # "<span drab-ampere='geztcmbqgu3tqnq'>"]}],
    IO.inspect final
    {:safe, final}
  end

  @doc false
  def handle_text({:safe, buffer}, text) do
    put_shadow_buffer(text, partial(buffer))
    {:safe, quote do
      [unquote(buffer), unquote(text)]
    end}
  end

  @doc false
  def handle_text("", text) do
    handle_text({:safe, ""}, text)
  end

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
    html = to_html(buffer)

    line = line_from_expr(expr)
    expr = Macro.prewalk(expr, &handle_assign/1)

    # if partial(buffer) == :guzdmmrvga4de do
    #   IO.puts "in mini:"
    #   IO.inspect expr
    # end

    # check if the expression is inside the tag or not
    {injected, shadow} = if Regex.match?(~r/<\S+/s, no_tags(html)) do
      inject_attribute(buffer, expr, line, html)
    else
      tag = in_tags(html, @special_tags)
      if tag do
        inject_tag(buffer, expr, line, tag)
      else
        inject_span(buffer, expr, line)
      end
    end

    put_shadow_buffer(shadow, partial(buffer))
    {:safe, injected}
  end


  # The expression is inside the <script> tag
  defp inject_tag(buffer, expr, line, tag) do
    if contains_nested_expression?(expr) do
      raise_nested_expression(buffer, line)
    end

    found_assigns  = find_assigns(expr)

    buffer = inject_drab_id(buffer, expr, tag)
    html = to_html(buffer)
    ampere_id = drab_id(html, tag)

    hash = hash({expr, found_assigns})
    Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

    {quote do
      [unquote(buffer), unquote(to_safe(expr, line))]
    end, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  end



  # Easy way. Surroud the expression with Drab Span
  defp inject_span(buffer, expr, line) do
    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    # tag = last_opened_tag(to_html(buffer)) || raise EEx.SyntaxError, message: """
    #   Can't find the parent tag for an expression.
    #   """
    # IO.inspect buffer
    # buffer = inject_drab_id(buffer, expr, tag)
    ampere_id = hash({buffer, expr})
    attribute = "#{@drab_id}=\"#{ampere_id}\""
    {buffer, _attribute} = case inject_attribute_to_last_opened(buffer, attribute) do
      {:ok, buf, _} -> {buf, attribute} # injected!
      {:already_there, _, attr} -> {buffer, attr} # it was already there
      {:not_found, _, _} -> raise EEx.SyntaxError, message: """
      Can't find the parent tag for an expression.
      """
    end
    # html = to_html(buffer)
    # ampere_id = drab_id(html, tag)

    hash = hash({expr, found_assigns})
    safe_expr = to_safe(expr, line)
    Drab.Live.Cache.set(hash, {:expr, safe_expr, found_assigns})

    # span_begin = "<span #{@drab_id}='#{hash}'>"
    # span_end   = "</span>"

    span_begin = "{{{{@drab-expr-hash:#{hash}}}}}"
    span_end   = "{{{{/@drab-expr-hash:#{hash}}}}}"

    buf = if found_assigns? do
      quote do
        [unquote(buffer), unquote(span_begin), unquote(safe_expr), unquote(span_end)]
      end
    else
      quote do
        [unquote(buffer), unquote(safe_expr)]
      end
    end

    {buf, ["{{{{@drab-expr-hash:#{hash}}}}}"]}
  end

  # The expression is inside the attribute
  defp inject_attribute(buffer, expr, _html, line) do
    if contains_nested_expression?(expr) do
      raise_nested_expression(buffer, line)
    end

    found_assigns  = find_assigns(expr) |> Enum.sort()
    html = to_html(buffer)
    hash = hash({expr, found_assigns})
    Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

    # Add drab indicator
    tag       = last_naked_tag(html)
    # if it is inside the expression, do not assign ID
    # buffer    = if partial(buffer), do: inject_drab_id(buffer, expr, tag), else: buffer
    buffer    = inject_drab_id(buffer, expr, tag)
    html      = to_html(buffer)
    ampere_id = drab_id(html, tag)

    attribute = find_attr_in_html(html)
    # quots?    = attr_begins_with_quote?(html)
    unless partial(buffer) do
      # in the expression, create fake attribute
      unless Drab.Live.Cache.get(ampere_id) do
        Drab.Live.Cache.set(ampere_id, {:attribute, []})
      end
    end

    buf = if attribute && String.starts_with?(attribute, "@") do
      # special form @property=<%=expr%> can't contain anything except =
      unless proper_property(html) do
        raise EEx.SyntaxError, message: """
          syntax error in Drab property special form for tag: <#{tag}>, property: #{attribute}

          You can only combine one Elixir expression with the DOM Node property.
          Allowed:

              <tag @property=<%#=expression%>>

          Prohibited:

              <tag @property="other text <%=expression%>">
              <tag @property="<%=expression1%><%=expression2%>">
              <tag @property="<%=expression%>">
              <tag @property='<%=expression%>'>

          """
      end

      # IO.inspect Drab.Live.Cache.get(ampere_id)

      property = String.replace(attribute, ~r/^@/, "")
      {:attribute, attributes} = Drab.Live.Cache.get(ampere_id) || {:attribute, []}
      updated = [{:prop, property, "", [hash], found_assigns} | attributes] |> Enum.uniq()

      Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})
      Drab.Live.Cache.set(ampere_id, {:attribute, updated})

      quote do
        # [unquote(buffer) | unquote(to_safe(encoded_expr(expr), line))]
        #TODO: to_safe is realy not required
        [unquote(buffer), [
          "'",
          unquote(property),
          "{{{{",
          unquote(encoded_expr(expr)),
          "}}}}'"]]
      end
    else
      quote do
        [unquote(buffer), unquote(to_safe(expr, line))]
      end
    end

    {buf, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  end

  defp partial(body) do
    html = to_html(body)
    p = Regex.run ~r/<span.*drab-partial='([^']+)'/is, html
    #TODO: possibly dangerous - returning nil when partial not found
    # but should be OK as we use shadow buffer only for attributes and scripts
    if p, do: List.last(p) |> String.to_atom(), else: nil
  end

  @doc false
  def find_attr_in_html(html) do
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

  @doc false
  def proper_property(html) do
    args_removed = args_removed(html)
    if String.contains?(args_removed, "=") do
      v = args_removed
        |> String.split("=")
        |> List.last()
      !Regex.match?(~r/[^\s]/, v)
    else
      false
    end
  end

  defp args_removed(html) do
    html
    |> String.split(~r/<\S+/s)
    |> List.last()
    |> remove_full_args()
  end

  defp in_tags(html, tags) do
    Enum.find(tags, fn tag -> in_tag(html, tag) end)
  end

  # true if the expression is in <tag></tag>
  defp in_tag(html, tag) do
    (count_matches(html, ~r/<\s*#{tag}[^<>]*>/si) > count_matches(html, ~r/<\s*\/\s*#{tag}[^<>]*>/si)) || nil
  end

  defp count_matches(html, regex) do
    regex |> Regex.scan(html) |> Enum.count()
  end

  defp replace_in(string, tag, id) when is_binary(string) do
    if String.contains?(string, @drab_id) do
      string
    else
      # IO.inspect replace_last(string, find, replacement)
      replacement = "<#{tag} #{@drab_id}='#{id}'"
      replace_last(string, "<#{tag}", replacement)
    end
  end
  defp replace_in(list, tag, id) when is_list(list) do
    Enum.map(list, fn x -> replace_in(x, tag, id) end)
    # replace_in(List.last(list), )
    # list |> List.last() |> replace_in(tag)
  end
  defp replace_in(other, _, _), do: other

  defp inject_drab_id(buffer, expr, tag) do
    if buffer |> to_html() |> drab_id(tag) do
      buffer
    else
      IO.inspect buffer
      # [{:|, [],
      # [["\n<span drab-partial='guzdmmrvga4de'>\n"],
      #  "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\"></div>\n\n"]}]

      # [{:|, [], ["", "\n  <span @style.backgroundColor="]}]
      # [{:|, [], [["\n<span drab-partial='geytsmrsgeztona'>\n"], "\n"]}]
      # ["\n<span drab-partial='geytsmrsgeztona'>\n"]
      # [{:|, [], [["\n<span drab-partial='gezdgobtgqzdanq'>\n"], "<b>username: "]}]

      [last_expr] = buffer
      case last_expr do
        {:|, meta, list} ->
          last_elem = List.last(list)
          replaced = replace_in(last_elem, tag, hash({buffer, expr}))
          [{:|, meta, List.replace_at(list, -1, replaced)}]
        line when is_binary(line) -> buffer # TODO: replace
        #TODO: what about <%=><%=> ?
      end
    end
  end

  # find the drab id in the last tag
  @doc false
  def drab_id(html, tag) do
    tag = String.downcase(tag)
    case Floki.find(html, tag) |> List.last() do
      {^tag, attrs, _} ->
        {_, val} = Enum.find(attrs, {nil, nil}, fn {name, _} -> name == @drab_id end)
        val
      _ ->
        nil
    end
  end

  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/s, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/s, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/s, "")
  end

  # replace last occurence of pattern in the string
  defp replace_last(string, pattern, replacement) do
    String.replace(string, ~r/#{pattern}(?!.*#{pattern})/is, replacement)
  end

  defp take_at(list, index) do
    {item, _} = List.pop_at(list, index)
    item
  end

  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/s, "")


  defp script_tag([]), do: []
  defp script_tag(js) do
    ["<script drab-script>", js, "</script>"]
  end

  defp assign_js(partial, assign) do
    ["#{@jsvar}.assigns['#{partial}']['#{assign}'] = '", encoded_assign(assign), "';"]
  end


  defp encoded_assign(assign) do
    # TODO: should not create AST directly
    assign_expr = {:@, [@anno], [{assign, [@anno], nil}]}
    assign_expr = handle_assign(assign_expr)

    base64_encoded_expr(assign_expr)
  end

  defp base64_encoded_expr(expr) do
    {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Live, :Crypto]}, :encode64]},
       [@anno],
       [expr]}
  end

  defp encoded_expr(expr) do
    {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Core]}, :encode_js]},
       [@anno],
       [expr]}
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

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

  @doc false
  def to_html(body), do: do_to_html(body) |> List.flatten() |> Enum.join()

  defp do_to_html([]), do: []
  defp do_to_html(body) when is_binary(body), do: [body]
  defp do_to_html({_, _, list}) when is_list(list), do: do_to_html(list)
  defp do_to_html([head | rest]), do: do_to_html(head) ++ do_to_html(rest)
  defp do_to_html(_), do: []

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
        _ -> {node, acc}
      end
    end
    result |> Enum.uniq() |> Enum.sort()
  end

  defp contains_nested_expression?(expr) do
    {_, acc} = Macro.prewalk expr, [], fn node, acc ->
      case node do
        {atom, _, params} when is_atom(atom) and is_list(params) ->
          found = Enum.find params, fn param ->
            case param do
              string when is_binary(string) -> String.contains?(string, "<span #{@drab_id}='")
              _ -> false
            end
          end
          {node, [found | acc]}
        _ ->
          {node, acc}
      end
    end
    Enum.find acc, fn x -> !is_nil(x) end
  end

  defp raise_nested_expression(buffer, line) do
    raise EEx.SyntaxError, message: """
      nested exceptions are not allowed in attributes, properties, scripts or textareas

      The following are not allowed:

          <script>
            <%= if clause do %>
              <%= expression %>
            <% end %>>
          </script>

          <tag attribute="<%= if clause do %><%= expression %><% end %>">

      Do a flat expression instead:

          <script>
            <%= if clause do
              expression
            end %>
          </script>

          <tag attribute="<%= if clause, do: expression %>">
      """, file: Drab.Live.Cache.get({:partial, partial(buffer)}), line: line
  end

  @doc false
  def last_naked_tag(html) do
    html = String.replace(html, ~r/<.*>/s, "", global: true)
    Regex.scan(~r/<\s*([^\s<>\/]+)/s, html)
      |> List.last()
      |> List.last()
      |> String.replace(~r/\s+.*/s, "")
  end

  defp do_attributes_from_shadow([]), do: []
  defp do_attributes_from_shadow([head | rest]) do
    do_attributes_from_shadow(head) ++ do_attributes_from_shadow(rest)
  end
  defp do_attributes_from_shadow({_, attributes, children}) when is_list(attributes) do
    attributes ++ do_attributes_from_shadow(children)
  end
  defp do_attributes_from_shadow(_), do: []

  @doc false
  def attributes_from_shadow(shadow) do
    do_attributes_from_shadow(shadow)
      |> Enum.filter(fn {_, value} -> Regex.match?(~r/{{{{@\S+}}}}/, value) end)
      |> Enum.filter(fn {name, _} ->
        n = Regex.match?(~r/{{{{@\S+}}}}/, name)
        n && Logger.warn """
          Unknown attribute found in HTML Template.

          Drab works only with well defined attributes in HTML. You may use:
              <button class="btn <%= @button_class %>">
              <a href="<%= build_href(@site) %>">

          The following constructs are prohibited:
              <tag <%="attr='" <> @value <> "'"%>>
              <tag <%=build_attr(@name, @value)%>>

          This will not be updated by Drab Commander.
          """
        !n
        end)
      |> Enum.filter(fn {name, _} -> !String.starts_with?(name, "@") end)
  end

  @doc false
  def scripts_from_shadow(shadow) do
    tags_from_shadow(shadow, "script")
    # for {"script", _, [script]} <- Floki.find(shadow, "script"), Regex.match?(~r/{{{{@\S+}}}}/, script) do
    #   script
    # end
  end

  @doc false
  def tags_from_shadow(shadow, tag) do
    tag = String.downcase(tag)
    for {^tag, _, [contents]} <- Floki.find(shadow, tag), Regex.match?(~r/{{{{@\S+}}}}/, contents) do
      contents
    end
  end

  @doc false
  def expression_hashes_from_pattern(pattern) do
    Regex.scan(~r/{{{{@drab-ampere:[^@}]+@drab-expr-hash:([^@}]+)/, pattern)
      |> Enum.map(fn [_, expr_hash] -> expr_hash end)
  end

  defp assigns_from_pattern(pattern) do
    Enum.reduce(expression_hashes_from_pattern(pattern), [], fn(hash, acc) ->
      {:expr, _, assigns} = Drab.Live.Cache.get(hash)
      [assigns | acc]
    end)
      |> List.flatten()
      |> Enum.uniq()
  end

  @doc false
  def ampere_from_pattern(pattern) do
    Regex.run(~r/{{{{@drab-ampere:([^@}]+)/, pattern) |> List.last()
  end

  defp start_shadow_buffer(initial, partial) do
    case Agent.start_link(fn -> initial end, name: partial) do
      {:ok, _} = ret ->
        ret
      {:error, {:already_started, _}} ->
        raise EEx.SyntaxError, message: """
          Expected unexpected.
          Shadow buffer Agent for #{partial} already started. Please report it as a bug in https://github.com/grych/drab
          """
    end
  end

  defp stop_shadow_buffer(partial) do
    Agent.stop(partial)
  end

  defp put_shadow_buffer(content, partial) do
    partial && Agent.update(partial, &[content | &1])
  end

  defp get_shadow_buffer(partial) do
    Agent.get(partial, &(&1)) |> Enum.reverse |> Enum.join()
  end
end
