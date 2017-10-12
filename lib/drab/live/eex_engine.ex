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
  # @special_tags ["script", "textarea"]

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
    # Drab.Live.Cache.set({:partial, partial}, partial_hash)
    # Drab.Live.Cache.set({:partial, partial_hash}, partial)

    buffer = "\n<span drab-partial='#{partial_hash}'>\n"
    # start_shadow_buffer(buffer, partial_hash |> String.to_atom()) # can't leak, only in compile-time
    {:safe, buffer}
  end

  @doc false
  def handle_body({:safe, body}) do
    body = List.flatten(body)

    partial_hash = partial(body)
    if partial_hash == "gi3tgnrzg44tmnbs" do
      IO.inspect body
    end
    found_assigns = find_assigns(body)
    assigns_js = found_assigns |> Enum.map(fn assign ->
      assign_js(partial_hash, assign)
    end) |> script_tag()

    init_js = """
      if (typeof window.#{@jsvar} == 'undefined') {#{@jsvar} = {assigns: {}, properties: {}}};
      #{@jsvar}.assigns['#{partial_hash}'] = {};
      """
    # put_shadow_buffer("\n</span>\n", partial)

    # shadow = get_shadow_buffer(partial(body)) |> Floki.parse()
    # Drab.Live.Cache.set({:shadow, partial(body)}, shadow)
    # stop_shadow_buffer(partial(body))

    # find all the attributes
    # add to cache:
    # expression hash is alrady in cache:  hash, {:expr, expr, found_assigns}
    # drab_ampere -> {:attribute, [ { "attribute", "pattern", [ {:expr, ast, [assigns] ] } ], all_assigns_in_ampere}
    # attributes = attributes_from_shadow(shadow)
    # grouped_by_ampere = Enum.map(attributes, fn {attribute, pattern} ->
    #   # is_prop? = String.starts_with?(attribute, "@")
    #   {ampere_from_pattern(pattern),
    #     {
    #       :attr,
    #       # (if is_prop?, do: :prop, else: :attr),
    #       # (if is_prop?, do: String.replace(attribute, ~r/^\@/, ""), else: attribute),
    #       attribute,
    #       pattern,
    #       expression_hashes_from_pattern(pattern),
    #       assigns_from_pattern(pattern)
    #     }
    #   }
    # end) |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

    # for {ampere, list} <- grouped_by_ampere do
    #   {:attribute, existing} = Drab.Live.Cache.get(ampere) || {:attribute, []}
    #   Drab.Live.Cache.set(ampere, {:attribute, Enum.uniq(existing ++ list)})
    # end

    # scripts, textareas
    # for tag <- @special_tags, pattern <- tags_from_shadow(shadow, tag) do
    #   ampere = ampere_from_pattern(pattern)
    #   hashes = expression_hashes_from_pattern(pattern)
    #   assigns = assigns_from_pattern(pattern)
    #   Drab.Live.Cache.set(ampere, {String.to_atom(tag), pattern, hashes, assigns})
    # end



    # IO.inspect final



    # find and save amperes
    # format:
    # {"partial_hash", "ampere_id"} => [
    #   {:html, "tag", "innerHTML", [pattern], [assigns]},
    #   {:attr, "tag", "attribute", [pattern], [assigns]}, {:attr...},
    #   {:prop, "tag", "property", [pattern], [assigns]}, {:prop...},
    # ]
    # where pattern = ["text", {expression}, "text"...]
    # found_amperes = amperes_from_buffer({:safe, List.flatten(body)})
    found_amperes = amperes_from_buffer({:safe, body})
    if partial_hash == "gi3tgnrzg44tmnbs" do
      IO.puts "Found amperes:"
      IO.inspect found_amperes
      IO.puts ""
    end
    # IO.inspect body
    amperes_to_assigns = for {ampere_id, vals} <- found_amperes do
      ampere_values = for {gender, tag, prop_or_attr, pattern} <- vals do
        compiled =
          compiled_from_pattern(gender, pattern, tag, prop_or_attr)
          |> remove_drab_marks()
        assigns = assigns_from_pattern(pattern)
        # if partial_hash == "gi3tgnrzg44tmnbs" do
        #   IO.puts ""
        #   IO.inspect {gender, tag, prop_or_attr, assigns, pattern}
        #   IO.puts ""
        # end
        {gender, tag, prop_or_attr, compiled, assigns}
      end
      Drab.Live.Cache.set({partial_hash, ampere_id}, ampere_values)
      # IO.inspect {{partial_hash, ampere_id}, ampere_values}
      for {_, _, _, _, assigns} <- ampere_values, assign <- assigns do
        {assign, ampere_id}
      end
    end
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)


    # ampere-to_assign list
    # {partial_hash, :assign} => ["ampere_ids"]
    for {assign, amperes} <- amperes_to_assigns do
      Drab.Live.Cache.set({partial_hash, assign}, amperes)
    end

    # other cached stuff:
    # "expr_hash" => {:expr, "expr", [assigns]}
    # "partial_hash" => {"partial_path", [assigns]}
    # "partial_path" => {"partial_hash", [assigns]
    partial_path = Drab.Live.Cache.get(partial_hash)
    # if partial_hash == "gi3tgnrzg44tmnbs" do
    #   IO.puts ""
    #   IO.puts "partial assigns"
    #   IO.inspect found_assigns
    #   IO.puts ""
    # end
    Drab.Live.Cache.set(partial_hash, {partial_path, found_assigns})
    Drab.Live.Cache.set(partial_path, {partial_hash, found_assigns})

    # property_js(partial, ampere, property, value)
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
    # IO.inspect properies_js

    final = [
      remove_drab_marks(body),
      "\n</span>\n",
      script_tag(init_js),
      assigns_js,
      properies_js
    ] |> List.flatten()

    # IO.inspect final

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
    # IO.puts "PAT::::::::"
    # IO.inspect expressions
    # IO.puts ""
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
    # put_shadow_buffer(text, partial(buffer))
    {:safe, quote do
      [unquote(buffer), unquote(text)]
    end}
  end

  @doc false
  def handle_text("", text) do
    handle_text({:safe, ""}, text)
  end

  # @doc false
  # def handle_begin(previous) do
  #   IO.puts "BEGIN"
  #   # IO.inspect previous
  #   {:safe, "BEGIN"}
  # end

  @doc false
  def handle_end(quoted) do
    # do not drab anything inside the expression, all is handled by the parent
    remove_drab_marks(quoted)
    # quoted
  end

  @doc false
  def handle_expr("", marker, expr) do
    handle_expr({:safe, ""}, marker, expr)
  end

  @doc false
  def handle_expr({:safe, buffer}, "", expr) do
    # IO.puts ""
    # IO.puts "EXPR:"
    # IO.inspect expr
    expr = Macro.prewalk(expr, &handle_assign/1)
    {:safe, quote do
      tmp2 = unquote(buffer)
      unquote(expr)
      tmp2
    end}
  end

  @doc false
  def handle_expr({:safe, buffer}, "=", expr) do
    # IO.inspect to_html(buffer)
    # html = to_html(buffer)
    # IO.puts ""
    # IO.puts "EXPR=:"
    # IO.inspect expr
    # IO.puts "BUFFER:"
    # IO.inspect buffer

    line = line_from_expr(expr)
    expr = Macro.prewalk(expr, &handle_assign/1)
    # IO.inspect shallow_find_assigns(expr)

    # found_assigns = shallow_find_assigns(expr)
    found_assigns = find_assigns(expr)
    found_assigns? = found_assigns != []

    ampere_id = hash({buffer, expr})
    attribute = "#{@drab_id}=\"#{ampere_id}\""

    html = buffer |> to_flat_html()
    if partial(buffer) == "gi3tgnrzg44tmnbs" do
      IO.puts ""
      # IO.inspect buffer
      IO.puts ""
    end
    inject_span? = not in_opened_tag?(buffer)
    # inject_span? = false

    # IO.inspect buffer
    # found_assigns? = false
    buffer = if !inject_span? && found_assigns? do
      # {a, b, c} = inject_attribute_to_last_opened(buffer, attribute)
      # IO.inspect {a, c}
      case inject_attribute_to_last_opened(buffer, attribute) do
        {:ok, buf, _}          -> buf    # injected!
        {:already_there, _, _} -> buffer # it was already there
        {:not_found, _, _}     -> raise EEx.SyntaxError, message: """
          can't find the parent tag for an expression in line #{line}.

          If the expression is inside the block (do, else):

              <%= if clause do %>
                <%= expression(@assign) %>
              <% end %>

          must be sourrounded by the html tag:

              <%= if clause do %>
                <span>
                  <%= expression(@assign) %>
                </span>
              <% end %>
          """
      end
    else
      buffer
    end

    hash = hash(expr)
    # IO.inspect hash
    # expr = to_safe(expr, line)
    Drab.Live.Cache.set(hash, {:expr, buffer, remove_drab_marks(expr), found_assigns})
    # require IEx; IEx.pry
    #TODO: REFACTOR
    attr = html |> find_attr_in_html()
    is_property = Regex.match?(~r/<\S+/s, no_tags(html)) && attr && String.starts_with?(attr, "@")
    expr = if is_property, do: encoded_expr(expr), else: to_safe(expr, line)

    span_begin = "<span #{attribute}>"
    span_end   = "</span>"

    expr_begin = "{{{{@drab-expr-hash:#{hash}}}}}"
    expr_end   = "{{{{/@drab-expr-hash:#{hash}}}}}"

    # inject_span? = false
    buf = if inject_span? do
      quote do
        tmp1 = unquote(buffer)
        [tmp1, unquote(span_begin), unquote(expr_begin), unquote(expr), unquote(expr_end), unquote(span_end)]
      end
    else
      quote do
        tmp1 = unquote(buffer)
        [tmp1, unquote(expr_begin), unquote(expr), unquote(expr_end)]
      end
    end

    # IO.inspect expr
    # found_assigns? = true
    # buf = if found_assigns? do
    #   quote do
    #     tmp1 = unquote(buffer)
    #     [tmp1, unquote(span_begin), unquote(expr_begin), unquote(expr), unquote(expr_end), unquote(span_end)]
    #   end
    # else
    #   quote do
    #     # [unquote(buffer), unquote(expr)]
    #     tmp1 = unquote(buffer)
    #     [tmp1, unquote(expr)]
    #   end
    # end

    {:safe, buf}
  end


  # # The expression is inside the <script> tag
  # defp inject_tag(buffer, expr, line, tag) do
  #   if contains_nested_expression?(expr) do
  #     raise_nested_expression(buffer, line)
  #   end

  #   found_assigns  = find_assigns(expr)

  #   buffer = inject_drab_id(buffer, expr, tag)
  #   html = to_html(buffer)
  #   ampere_id = drab_id(html, tag)

  #   hash = hash({expr, found_assigns})
  #   Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

  #   {quote do
  #     [unquote(buffer), unquote(to_safe(expr, line))]
  #   end, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  # end



  # # Easy way. Surroud the expression with Drab Span
  # defp inject_span(buffer, expr, line) do
  #   found_assigns  = find_assigns(expr)
  #   found_assigns? = found_assigns != []

  #   ampere_id = hash({buffer, expr})
  #   attribute = "#{@drab_id}=\"#{ampere_id}\""
  #   {buffer, _attribute} = case inject_attribute_to_last_opened(buffer, attribute) do
  #     {:ok, buf, _} -> {buf, attribute} # injected!
  #     {:already_there, _, attr} -> {buffer, attr} # it was already there
  #     {:not_found, _, _} -> raise EEx.SyntaxError, message: """
  #       Can't find the parent tag for an expression.
  #       """
  #   end
  #   # html = to_html(buffer)
  #   # ampere_id = drab_id(html, tag)

  #   # {a, _, args} = expr # remove meta (line number) from expression

  #   attribute = buffer |> to_html() |> find_attr_in_html()
  #   is_property = attribute && String.starts_with?(attribute, "@")

  #   hash = hash(expr)
  #   Drab.Live.Cache.set(hash, {:expr, remove_drab_marks(expr), found_assigns})

  #   expr = if is_property, do: encoded_expr(expr), else: to_safe(expr, line)

  #   # span_begin = "<span #{@drab_id}='#{hash}'>"
  #   # span_end   = "</span>"

  #   expr_begin = "{{{{@drab-expr-hash:#{hash}}}}}"
  #   expr_end   = "{{{{/@drab-expr-hash:#{hash}}}}}"

  #   buf = if found_assigns? do
  #     quote do
  #       [unquote(buffer), unquote(expr_begin), unquote(expr), unquote(expr_end)]
  #     end
  #   else
  #     quote do
  #       [unquote(buffer), unquote(expr)]
  #     end
  #   end

  #   {buf, ["{{{{@drab-expr-hash:#{hash}}}}}"]}
  # end

  # # The expression is inside the attribute
  # defp inject_attribute(buffer, expr, _html, line) do
  #   if contains_nested_expression?(expr) do
  #     raise_nested_expression(buffer, line)
  #   end

  #   found_assigns  = find_assigns(expr) |> Enum.sort()
  #   html = to_html(buffer)
  #   hash = hash({expr, found_assigns})
  #   Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})

  #   # Add drab indicator
  #   tag       = last_naked_tag(html)
  #   # if it is inside the expression, do not assign ID
  #   # buffer    = if partial(buffer), do: inject_drab_id(buffer, expr, tag), else: buffer
  #   buffer    = inject_drab_id(buffer, expr, tag)
  #   html      = to_html(buffer)
  #   ampere_id = drab_id(html, tag)

  #   attribute = find_attr_in_html(html)
  #   # quots?    = attr_begins_with_quote?(html)
  #   unless partial(buffer) do
  #     # in the expression, create fake attribute
  #     unless Drab.Live.Cache.get(ampere_id) do
  #       Drab.Live.Cache.set(ampere_id, {:attribute, []})
  #     end
  #   end

  #   buf = if attribute && String.starts_with?(attribute, "@") do
  #     # special form @property=<%=expr%> can't contain anything except =
  #     unless proper_property(html) do
  #       raise EEx.SyntaxError, message: """
  #         syntax error in Drab property special form for tag: <#{tag}>, property: #{attribute}

  #         You can only combine one Elixir expression with the DOM Node property.
  #         Allowed:

  #             <tag @property=<%#=expression%>>

  #         Prohibited:

  #             <tag @property="other text <%=expression%>">
  #             <tag @property="<%=expression1%><%=expression2%>">
  #             <tag @property="<%=expression%>">
  #             <tag @property='<%=expression%>'>

  #         """
  #     end

  #     # IO.inspect Drab.Live.Cache.get(ampere_id)

  #     property = String.replace(attribute, ~r/^@/, "")
  #     {:attribute, attributes} = Drab.Live.Cache.get(ampere_id) || {:attribute, []}
  #     updated = [{:prop, property, "", [hash], found_assigns} | attributes] |> Enum.uniq()

  #     Drab.Live.Cache.set(hash, {:expr, expr, found_assigns})
  #     Drab.Live.Cache.set(ampere_id, {:attribute, updated})

  #     quote do
  #       # [unquote(buffer) | unquote(to_safe(encoded_expr(expr), line))]
  #       #TODO: to_safe is realy not required
  #       [unquote(buffer), [
  #         "'",
  #         unquote(property),
  #         "{{{{",
  #         unquote(encoded_expr(expr)),
  #         "}}}}'"]]
  #     end
  #   else
  #     quote do
  #       [unquote(buffer), unquote(to_safe(expr, line))]
  #     end
  #   end

  #   {buf, "{{{{@#{@drab_id}:#{ampere_id}@drab-expr-hash:#{hash}}}}}"}
  # end

  defp partial(body) do
    html = to_flat_html(body)
    p = Regex.run ~r/<span.*drab-partial='([^']+)'/is, html
    #TODO: possibly dangerous - returning nil when partial not found
    # but should be OK as we use shadow buffer only for attributes and scripts
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

  # @doc false
  # def proper_property(html) do
  #   args_removed = args_removed(html)
  #   if String.contains?(args_removed, "=") do
  #     v = args_removed
  #       |> String.split("=")
  #       |> List.last()
  #     !Regex.match?(~r/[^\s]/, v)
  #   else
  #     false
  #   end
  # end



  # defp in_tags(html, tags) do
  #   Enum.find(tags, fn tag -> in_tag(html, tag) end)
  # end

  # # true if the expression is in <tag></tag>
  # defp in_tag(html, tag) do
  #   (count_matches(html, ~r/<\s*#{tag}[^<>]*>/si) > count_matches(html, ~r/<\s*\/\s*#{tag}[^<>]*>/si)) || nil
  # end

  # defp count_matches(html, regex) do
  #   regex |> Regex.scan(html) |> Enum.count()
  # end

  # defp replace_in(string, tag, id) when is_binary(string) do
  #   if String.contains?(string, @drab_id) do
  #     string
  #   else
  #     # IO.inspect replace_last(string, find, replacement)
  #     replacement = "<#{tag} #{@drab_id}='#{id}'"
  #     replace_last(string, "<#{tag}", replacement)
  #   end
  # end
  # defp replace_in(list, tag, id) when is_list(list) do
  #   Enum.map(list, fn x -> replace_in(x, tag, id) end)
  #   # replace_in(List.last(list), )
  #   # list |> List.last() |> replace_in(tag)
  # end
  # defp replace_in(other, _, _), do: other

  # defp inject_drab_id(buffer, expr, tag) do
  #   if buffer |> to_html() |> drab_id(tag) do
  #     buffer
  #   else
  #     # IO.inspect buffer

  #     # [{:|, [],
  #     # [["\n<span drab-partial='guzdmmrvga4de'>\n"],
  #     #  "<div id=\"begin\" style=\"display: none;\"></div>\n<div id=\"drab_pid\" style=\"display: none;\"></div>\n\n"]}]

  #     # [{:|, [], ["", "\n  <span @style.backgroundColor="]}]
  #     # [{:|, [], [["\n<span drab-partial='geytsmrsgeztona'>\n"], "\n"]}]
  #     # ["\n<span drab-partial='geytsmrsgeztona'>\n"]
  #     # [{:|, [], [["\n<span drab-partial='gezdgobtgqzdanq'>\n"], "<b>username: "]}]

  #     [last_expr] = buffer
  #     case last_expr do
  #       {:|, meta, list} ->
  #         last_elem = List.last(list)
  #         replaced = replace_in(last_elem, tag, hash({buffer, expr}))
  #         [{:|, meta, List.replace_at(list, -1, replaced)}]
  #       line when is_binary(line) -> buffer # TODO: replace
  #       #TODO: what about <%=><%=> ?
  #     end
  #   end
  # end

  # find the drab id in the last tag
  # @doc false
  # defp drab_id(html, tag) do
  #   tag = String.downcase(tag)
  #   case Floki.find(html, tag) |> List.last() do
  #     {^tag, attrs, _} ->
  #       {_, val} = Enum.find(attrs, {nil, nil}, fn {name, _} -> name == @drab_id end)
  #       val
  #     _ ->
  #       nil
  #   end
  # end

  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/s, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/s, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/s, "")
  end

  # replace last occurence of pattern in the string
  # defp replace_last(string, pattern, replacement) do
  #   String.replace(string, ~r/#{pattern}(?!.*#{pattern})/is, replacement)
  # end

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
    # ["document.querySelector('[drab-ampere=#{ampere}]').#{property}=", value, ";"]
  end


  defp encoded_assign(assign) do
    # TODO: should not create AST directly
    # quote line: meta[:line] || 0 do
    #   Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(name))
    # end

    # assign_expr = {:@, [@anno], [{assign, [@anno], nil}]}
    # assign_expr = handle_assign(assign_expr)

    assign_expr = quote @anno do
      Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(assign))
    end

    base64_encoded_expr(assign_expr)
  end

  defp base64_encoded_expr(expr) do
    quote @anno do
      Drab.Live.Crypto.encode64(unquote(expr))
    end
    # {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Live, :Crypto]}, :encode64]},
    #    [@anno],
    #    [expr]}
  end

  @doc false
  def encoded_expr(expr) do
    quote @anno do
      Drab.Core.encode_js(unquote(expr))
    end
    # {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Core]}, :encode_js]},
    #    [@anno],
    #    [expr]}
  end

  # @doc false
  # def safe_expr(expr) do
  #   quote @anno do
  #     Phoenix.HTML.html_escape(unquote(expr))
  #   end
  # end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  @doc false
  def to_safe(literal), do: to_safe(literal, @anno)

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
        _ ->
          {node, acc}
      end
    end
    result |> Enum.uniq() |> Enum.sort()
  end

  @doc false
  def shallow_find_assigns(ast) do
    {_, assigns} = do_find(ast, [])
    assigns
  end

  # do not search under the
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

  # defp contains_nested_expression?(expr) do
  #   {_, acc} = Macro.prewalk expr, [], fn node, acc ->
  #     case node do
  #       {atom, _, params} when is_atom(atom) and is_list(params) ->
  #         found = Enum.find params, fn param ->
  #           case param do
  #             string when is_binary(string) -> String.contains?(string, "<span #{@drab_id}='")
  #             _ -> false
  #           end
  #         end
  #         {node, [found | acc]}
  #       _ ->
  #         {node, acc}
  #     end
  #   end
  #   Enum.find acc, fn x -> !is_nil(x) end
  # end

  # defp raise_nested_expression(buffer, line) do
  #   raise EEx.SyntaxError, message: """
  #     nested exceptions are not allowed in attributes, properties, scripts or textareas

  #     The following are not allowed:

  #         <script>
  #           <%= if clause do %>
  #             <%= expression %>
  #           <% end %>>
  #         </script>

  #         <tag attribute="<%= if clause do %><%= expression %><% end %>">

  #     Do a flat expression instead:

  #         <script>
  #           <%= if clause do
  #             expression
  #           end %>
  #         </script>

  #         <tag attribute="<%= if clause, do: expression %>">
  #     """, file: Drab.Live.Cache.get({:partial, partial(buffer)}), line: line
  # end

  # defp last_naked_tag(html) do
  #   html = String.replace(html, ~r/<.*>/s, "", global: true)
  #   Regex.scan(~r/<\s*([^\s<>\/]+)/s, html)
  #     |> List.last()
  #     |> List.last()
  #     |> String.replace(~r/\s+.*/s, "")
  # end

  # defp do_attributes_from_shadow([]), do: []
  # defp do_attributes_from_shadow([head | rest]) do
  #   do_attributes_from_shadow(head) ++ do_attributes_from_shadow(rest)
  # end
  # defp do_attributes_from_shadow({_, attributes, children}) when is_list(attributes) do
  #   attributes ++ do_attributes_from_shadow(children)
  # end
  # defp do_attributes_from_shadow(_), do: []

  # defp attributes_from_shadow(shadow) do
  #   do_attributes_from_shadow(shadow)
  #     |> Enum.filter(fn {_, value} -> Regex.match?(~r/{{{{@\S+}}}}/, value) end)
  #     |> Enum.filter(fn {name, _} ->
  #       n = Regex.match?(~r/{{{{@\S+}}}}/, name)
  #       n && Logger.warn """
  #         Unknown attribute found in HTML Template.

  #         Drab works only with well defined attributes in HTML. You may use:
  #             <button class="btn <%= @button_class %>">
  #             <a href="<%= build_href(@site) %>">

  #         The following constructs are prohibited:
  #             <tag <%="attr='" <> @value <> "'"%>>
  #             <tag <%=build_attr(@name, @value)%>>

  #         This will not be updated by Drab Commander.
  #         """
  #       !n
  #       end)
  #     |> Enum.filter(fn {name, _} -> !String.starts_with?(name, "@") end)
  # end

  # defp scripts_from_shadow(shadow) do
  #   tags_from_shadow(shadow, "script")
  #   # for {"script", _, [script]} <- Floki.find(shadow, "script"), Regex.match?(~r/{{{{@\S+}}}}/, script) do
  #   #   script
  #   # end
  # end

  # defp tags_from_shadow(shadow, tag) do
  #   tag = String.downcase(tag)
  #   for {^tag, _, [contents]} <- Floki.find(shadow, tag), Regex.match?(~r/{{{{@\S+}}}}/, contents) do
  #     contents
  #   end
  # end

  # defp expression_hashes_from_pattern(pattern) do
  #   Regex.scan(~r/{{{{@drab-ampere:[^@}]+@drab-expr-hash:([^@}]+)/, pattern)
  #     |> Enum.map(fn [_, expr_hash] -> expr_hash end)
  # end

  # defp assigns_from_pattern(pattern) do
  #   Enum.reduce(expression_hashes_from_pattern(pattern), [], fn(hash, acc) ->
  #     {:expr, _, assigns} = Drab.Live.Cache.get(hash)
  #     [assigns | acc]
  #   end)
  #     |> List.flatten()
  #     |> Enum.uniq()
  # end

  # defp ampere_from_pattern(pattern) do
  #   Regex.run(~r/{{{{@drab-ampere:([^@}]+)/, pattern) |> List.last()
  # end

  # defp start_shadow_buffer(initial, partial) do
  #   case Agent.start_link(fn -> initial end, name: partial) do
  #     {:ok, _} = ret ->
  #       ret
  #     {:error, {:already_started, _}} ->
  #       raise EEx.SyntaxError, message: """
  #         Expected unexpected.
  #         Shadow buffer Agent for #{partial} already started. Please report it as a bug in https://github.com/grych/drab
  #         """
  #   end
  # end

  # defp stop_shadow_buffer(partial) do
  #   Agent.stop(partial)
  # end

  # defp put_shadow_buffer(content, partial) do
  #   partial && Agent.update(partial, &[content | &1])
  # end

  # defp get_shadow_buffer(partial) do
  #   Agent.get(partial, &(&1)) |> Enum.reverse |> Enum.join()
  # end
end
