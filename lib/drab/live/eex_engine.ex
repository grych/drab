defmodule Drab.Live.EExEngine do
  @moduledoc """
  This is an implementation of EEx.Engine that injects `Drab.Live` behaviour.

  It parses the template during compile-time and inject Drab markers into it. Because of this, template must be
  a proper HTML. Also, there are some rules to obey, see limitations below.

  ### Limitations

  #### Attributes
  The attribute must be well defined, and you can't use the expression as an attribute name.

  The following is valid:

      <button class="btn <%= @button_class %>">
      <a href="<%= build_href(@site) %>">

  But following constructs are prohibited:

      <tag <%="attr='" <> @value <> "'"%>>
      <tag <%=build_attr(@name, @value)%>>
  
  The above will compile (with warnings), but it will not be correctly updated with `Drab.Live.poke`.

  Also, the tag name can not be build with the expression.

      <<%= @tag_name %> attr=value ...>

  #### Scripts
  Like above, tag name must be defined as `<script>` and can't be defined with the expression.

  #### Properties
  Property must be defined inside the tag, using strict `@property.path.from.node=<%= expression %>` syntax.
  """

  import Drab.Live.Crypto
  # import Drab.Core
  use EEx.Engine
  require IEx
  require Logger

  @jsvar           "__drab"
  @drab_id         "drab-ampere"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  @doc false
  def init(opts) do
    partial = opts[:file] |> String.to_atom()
    Logger.info "Compiling Drab partial: #{partial}"
    Drab.Live.Cache.start()
    buffer = ["\n<span drab-partial='#{partial}'>\n"]
    start_shadow_buffer(buffer, partial)
    {:safe, buffer}
  end

  @doc false
  def handle_body({:safe, body}) do 
    found_assigns = find_assigns(body)
    partial = partial(body)
    assigns_js = found_assigns |> Enum.map(fn assign ->
      assign_js(assign)
    end) |> script_tag()

    init_js = "if (typeof window.#{@jsvar} == 'undefined') {window.#{@jsvar} = {}; window.#{@jsvar}.assigns = {}; window.#{@jsvar}.properties = {}}"
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
      is_prop? = String.starts_with?(attribute, "@")
      {ampere_from_pattern(pattern), 
        {
          (if is_prop?, do: :prop, else: :attr),
          (if is_prop?, do: String.replace(attribute, ~r/^\@/, ""), else: attribute), 
          pattern, 
          expression_hashes_from_pattern(pattern),
          assigns_from_pattern(pattern)
        }
      }
    end) |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

    for {ampere, list} <- grouped_by_ampere do
      Drab.Live.Cache.set(ampere, {:attribute, list})
    end

    properties = attributes
      |> Enum.filter(fn {name, _} -> String.starts_with?(name, "@") end)
    properties_js = properties
      |> Enum.map(&property_js/1)
    init_properties_js = properties 
      |> Enum.map(fn {_, pattern} ->
        x = ampere_from_pattern(pattern)
        "if (typeof #{@jsvar}.properties['#{x}'] == 'undefined') {#{@jsvar}.properties['#{x}'] = []};"
      end) |> Enum.uniq()

    # scripts
    for pattern <- scripts_from_shadow(shadow) do
      ampere = ampere_from_pattern(pattern)
      hashes = expression_hashes_from_pattern(pattern)
      assigns = assigns_from_pattern(pattern)
      Drab.Live.Cache.set(ampere, {:script, pattern, hashes, assigns})
    end

    final = [
      script_tag(init_js) |
      [assigns_js |
      [body |
      ["\n</span>\n" |
      [script_tag(init_properties_js) |
      [script_tag(properties_js)]]]]]
    ]

    {:safe, final}
  end

  @doc false
  def handle_text({:safe, buffer}, text) do
    put_shadow_buffer(text, partial(buffer))
    {:safe, quote do
      [unquote(buffer) | unquote(text)]
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

    # Decide if the expression is inside the tag or not
    {injected, shadow} = if Regex.match?(~r/<\S+/, no_tags(html)) do
      inject_attribute(buffer, expr, line, html)
    else
      if in_script?(html) do
        inject_script(buffer, expr, line)
      else
        inject_span(buffer, expr, line)
      end
    end
    put_shadow_buffer(shadow, partial(buffer))
    {:safe, injected}
  end

  # The expression is inside the <script> tag
  defp inject_script(buffer, expr, line) do
    found_assigns  = find_assigns(expr)

    buffer = inject_drab_id(buffer, "script")
    html = to_html(buffer)
    ampere_id = drab_id(html, "script")

    hash = hash({expr, found_assigns})
    Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

    {quote do
      [unquote(buffer) | unquote(to_safe(expr, line))]
    end, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  end



  # Easy way. Surroud the expression with Drab Span
  defp inject_span(buffer, expr, line) do
    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    hash = hash({expr, found_assigns})
    Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

    span_begin = "<span #{@drab_id}='#{hash}'>"
    span_end   = "</span>"

    buf = if found_assigns? do
      quote do
        [[[unquote(buffer) | unquote(span_begin)] | unquote(to_safe(expr, line))] | unquote(span_end)]
      end
    else 
      quote do
        [unquote(buffer) | unquote(to_safe(expr, line))]
      end
    end

    {buf, ["{{{{@drab-expr-hash:#{hash}}}}}"]}
  end

  # The expression is inside the attribute
  defp inject_attribute(buffer, expr, _html, line) do
    found_assigns  = find_assigns(expr) |> Enum.sort()
    html = to_html(buffer) 
    hash = hash({expr, found_assigns})
    Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

    # Add drab indicator
    tag       = last_opened_tag(html)
    buffer    = inject_drab_id(buffer, tag)
    html      = to_html(buffer)
    ampere_id = drab_id(html, tag)

    attribute = find_attr_in_html(html)
    # quots?    = attr_begins_with_quote?(html)

    buf = if attribute && String.starts_with?(attribute, "@") do
      # special form @property="<%=expr%>" can't contain anything except ", ' or =
      unless proper_property(html) do
        raise EEx.SyntaxError, message: """
          Syntax Error in Drab Property special form for tag: <#{tag}>, property: #{attribute}

          You can only combine one Elixir expression with the DOM Node property. 
          Allowed:

              <tag @property=<%=expression%>>
              <tag @property="<%=expression%>">
              <tag @property='<%=expression%>'>

          Prohibited:

              <tag @property="other text <%=expression%>">
              <tag @property="<%=expression1%><%=expression2%>">

          """
      end
      # if it is a property, encode it with JS safe
      quote do
        # [unquote(buffer) | unquote(to_safe(encoded_expr(expr), line))]
        [unquote(buffer) | unquote(attribute |> String.replace(~r/^@/, ""))]
      end
    else
      quote do
        [unquote(buffer) | unquote(to_safe(expr, line))]
      end
    end

    {buf, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  end

  defp partial(body) do
    html = to_html(body)
    p = Regex.run ~r/<span.*drab-partial='([^']+)'/i, html
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
      !Regex.match?(~r/[^\s'"]/, v)
    else
      false
    end
  end
  # @doc false
  # def attr_begins_with_quote?(html) do
  #   args_removed = args_removed(html)
  #   if String.contains?(args_removed, "=") do
  #     v = args_removed
  #     |> String.split("=") 
  #     |> List.last()
  #     Regex.match?(~r/\s*["']/, v)
  #   else
  #     nil
  #   end
  # end

  defp args_removed(html) do
    html
    |> String.split(~r/<\S+/)
    |> List.last()
    |> remove_full_args()
  end

  @start_script    ~r/<\s*script[^<>]*>/i
  @end_script      ~r/<\s*\/\s*script[^<>]*>/i
  defp in_script?(html) do
    # true if the expression is in <script></script>
    count_matches(html, @start_script) > count_matches(html, @end_script)
  end

  defp count_matches(html, regex) do
    regex |> Regex.scan(html) |> Enum.count()
  end

  #TODO: should really replace only last occurence in the whole nested list
  # now it assigns id to the innocent tags
  defp replace_in(string, tag) when is_binary(string) do
    if String.contains?(string, @drab_id) do
      string
    else
      # IO.inspect replace_last(string, find, replacement)
      replacement = "<#{tag} #{@drab_id}='#{uuid()}'"
      replace_last(string, "<#{tag}", replacement)
    end
  end
  defp replace_in(list, tag) when is_list(list) do
    Enum.map(list, fn x -> replace_in(x, tag) end)
    # replace_in(List.last(list), )
    # list |> List.last() |> replace_in(tag)
  end
  defp replace_in(other, _), do: other

  defp inject_drab_id(buffer, tag) do
    [last_expr] = buffer
    {:|, a, list} = last_expr
    [{:|, a, replace_in(list, tag)}]
  end
  # defp inject_drab_id(buffer, tag) do
  #   IO.puts ""
  #   IO.inspect buffer 
  #   IO.inspect tag
  #   IO.puts ""
  #   Macro.prewalk(buffer, fn expr -> 
  #     case expr do
  #       {:|, x, list} ->
  #         {:|, x, replace_in(list, tag)}
  #       other -> other
  #     end
  #   end)
  # end

  # find the drab id in the last tag
  @doc false
  def drab_id(html, tag) do
    r = ~r/<#{tag}[^<>]*#{@drab_id}\s*=\s*'(.*)'[^<>]*/isU
    did = Regex.scan(r, html) 
    if did == [] do
      nil
    else
      did |> List.last() |> List.last()
    end
  end

  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/, "")
  end

  # replace last occurence of pattern in the string
  defp replace_last(string, pattern, replacement) do
    String.replace(string, ~r/#{pattern}(?!.*#{pattern})/is, replacement)
  end

  defp take_at(list, index) do
    {item, _} = List.pop_at(list, index)
    item
  end

  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/, "")


  defp script_tag([]), do: []
  defp script_tag(js) do
    ["<script>", js, "</script>"]
  end

  defp assign_js(assign) do
    ["#{@jsvar}.assigns['#{assign}'] = ", encoded_assign(assign), ";"]
  end


  defp encoded_assign(assign) do
    # TODO: should not create AST directly
    assign_expr = {:@, [@anno], [{assign, [@anno], nil}]}
    assign_expr = handle_assign(assign_expr)

    encoded_expr(assign_expr)
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


  defp to_html(body), do: do_to_html(body) |> List.flatten() |> Enum.join()

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

  @doc false
  def last_opened_tag(html) do
    html = String.replace(html, ~r/<.*>/, "", global: true)
    Regex.scan(~r/<\s*([^\s<>\/]+)/, html)
      |> List.last()
      |> List.last()
      |> String.replace(~r/\s+.*/, "")
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
          But following constructs are prohibited:
              <tag <%="attr='" <> @value <> "'"%>>
              <tag <%=build_attr(@name, @value)%>>
          This will not be updated by Drab Commander.
          """
        !n
      end)
  end

  @doc false
  def scripts_from_shadow(shadow) do
    for {"script", _, [script]} <- Floki.find(shadow, "script"), Regex.match?(~r/{{{{@\S+}}}}/, script) do
      script
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

  defp property_js({name, pattern}) do
    name = String.replace(name, ~r/^\@/, "")
    ampere = ampere_from_pattern(pattern)
    {:expr, expr, _} = expression_hashes_from_pattern(pattern) |> List.first() |> Drab.Live.Cache.get()

    [ "#{@jsvar}.properties['#{ampere}'].push({'#{name}': " | [encoded_expr(expr) | ["});"]]]
    # [ 
    #   "Drab.update_prop('[#{@drab_id}=#{encode_js(ampere)}]', #{encode_js(name)}, ",
    #   encoded_expr(expr),
    #   ");"
    # ]
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
