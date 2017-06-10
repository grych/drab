defmodule Drab.Live.EExEngine do
  @moduledoc false

  import Drab.Live.Crypto
  use EEx.Engine
  require IEx

  @jsvar "__drab"
  @drab_indicator  "drabbed"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  @doc false
  def init(opts) do
    # [engine: Drab.Live.EExEngine,
    #  file: "test/support/web/templates/live/users.html.drab", line: 1]
    {:safe, ["\n", "\n", "<!-- DRAB BEGIN ", opts[:file], " -->", "\n"]}
  end

  @doc false
  def handle_body({:safe, body}) do 
    init_js = "if (typeof window.#{@jsvar} == 'undefined') {window.#{@jsvar} = {}; window.#{@jsvar}.assigns = {}}"
    {:safe, [script_tag(init_js), body, "<!-- DRAB END -->", "\n"]}
  end

  @doc false
  def handle_text({:safe, buffer}, text), do: Phoenix.HTML.Engine.handle_text({:safe, buffer}, text)

  @doc false
  def handle_text("", text), do: Phoenix.HTML.Engine.handle_text("", text)

  @doc false
  def handle_expr("", marker, expr), do: Phoenix.HTML.Engine.handle_expr("", marker, expr)

  @doc false
  def handle_expr({:safe, buffer}, "", expr), do: Phoenix.HTML.Engine.handle_expr({:safe, buffer}, "", expr)

  @doc false
  def handle_expr({:safe, buffer}, "=", expr) do
    html = plain_html(buffer) 
    # Decide if the expression is inside the tag or not
    if Regex.match?(~r/<\S+/, no_tags(html)) do
      {:safe, inject_attribute(buffer, expr, html)}
    else
      {:safe, inject_span(buffer, expr)}
    end
  end

  # Easy way. Surroud the expression with Drab Span
  defp inject_span(buffer, expr) do
    line           = line_from_expr(expr)
    expr           = Macro.prewalk(expr, &handle_assign/1)

    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    hash = hash({:ampere, expr, found_assigns})
    Drab.Live.Cache.add(hash, {:ampere, expr, found_assigns})

    span_begin = "<span drab-expr='#{hash}'>"
    span_end   = "</span>"

    # do not repeat assign javascript
    as = deduplicated_js_lines(buffer, found_assigns)
    assigns_js = script_tag(as)

    if found_assigns? do
      quote do
        [unquote(buffer), unquote(span_begin), unquote(to_safe(expr, line)), unquote(span_end), unquote(assigns_js)]
      end
    else 
      quote do
        [unquote(buffer), unquote(to_safe(expr, line))]
      end
    end
  end

  # The expression is inside the attribute
  # In this case we need to inject the attribute, `drab-attr-HASH`, refering to the tuple in the Cache,
  # which contains expression, assigns and the attribute name
  defp inject_attribute(buffer, expr, _html) do
    line           = line_from_expr(expr)
    expr           = Macro.prewalk(expr, &handle_assign/1)

    found_assigns  = find_assigns(expr) |> Enum.sort()
    found_assigns? = found_assigns != []

    # do not repeat assign javascript
    assigns_js = deduplicated_js_lines(buffer, found_assigns) |> script_tag()

    lastline = last_line(buffer)
    attribute = find_attr_in_line(lastline)

    hash = hash({:attributed, expr, found_assigns, attribute})
    Drab.Live.Cache.add(hash, {:attributed, expr, found_assigns, attribute})

    # Add drabbed indicator, only once
    drabbed = if Regex.match?(~r/<\S+/, lastline), do: "#{@drab_indicator} ", else: ""

    # Add Drab Attribute just before the attribute
    injected_line =
      replace_last(lastline, attribute, "#{drabbed}drab-attr-#{hash} #{attribute}")

    # Hack the buffer by replacing the last line
    [{a, b, list}] = buffer
    buffer = [{a, b, List.replace_at(list, -1, injected_line)}]

    if found_assigns? do
      quote do
        # [unquote(assigns_js), unquote(buffer), unquote(to_safe(expr, line)), unquote(attr)]
        [unquote(assigns_js), unquote(buffer), unquote(to_safe(expr, line))]
      end
    else
      quote do
        [unquote(buffer), unquote(to_safe(expr, line))]
      end
    end
  end

  @doc false
  def find_attr_in_line(line) do
    args_removed = line
    |> String.split(~r/<\S+/)
    |> take_at(-1)
    |> remove_full_args()

    unless String.contains?(args_removed, "=") do
      raise CompileError, description: """
        Invalid attribute in html template:
          `#{IO.inspect line}`
        You must specify the the attribute in the tag, like:
          <tag attribute="<%= my_func() %>">
          <tag attribute='<%= @attr <> @attr2 %>'>
          <tag attribute=<%= my_func(@attr) %>>
        The following attribute injection is forbidden:
          <tag <%= @whole_attribute %>>
        Or you tried to include the "<" character in your page: you should escape it as "&lt;"
        """
    end

    line
    |> String.split("=") 
    |> take_at(-2)
    |> String.split(~r/\s+/)
    |> Enum.filter(fn x -> x != "" end)
    |> List.last()
  end

  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'.*'/, "")
    |> String.replace(~r/\S+\s*=\s*".*"/, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/, "")
  end

  defp replace_last(string, pattern, replacement) do
    String.reverse(string)
    |> String.replace(String.reverse(pattern), String.reverse(replacement), global: false) 
    |> String.reverse()
  end

  defp take_at(list, index) do
    {item, _} = List.pop_at(list, index)
    item
  end

  defp last_line(buffer) do
    [{:|, _, a}] = buffer
    List.last(a)
  end

  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/, "")

  defp deduplicated_js_lines(buffer, found_assigns) do
    found_assigns |> Enum.map(fn assign ->
      # TODO: find a better way to search in buffer, rather than string-based
      if deep_find(buffer, assign_js(assign) |> List.first()) do
        []
      else
        assign_js(assign)
      end
    end) |> List.flatten()    
  end

  defp script_tag([]), do: []
  defp script_tag(js) do
    ["\n", "<script>", js, "</script>"]
  end

  defp assign_js(assign) do
    ["#{@jsvar}.assigns['#{assign}'] = '", assign_expr(assign), "';"]
  end

  defp assign_expr(assign) do
    # TODO: should not create AST directly
    assign_expr = {:@, [@anno], [{assign, [@anno], nil}]}
    assign_expr = handle_assign(assign_expr)

    {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Live, :Crypto]}, :encode64]},
       [@anno], 
       [assign_expr]}
  end

  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  # We can do the work at compile time
  defp to_safe(literal, _line) when is_binary(literal) or is_atom(literal) or is_number(literal) do
    Phoenix.HTML.Safe.to_iodata(literal)
  end

  # We can do the work at runtime
  defp to_safe(literal, line) when is_list(literal) do
    quote line: line, do: Phoenix.HTML.Safe.to_iodata(unquote(literal))
  end

  # We need to check at runtime and we do so by
  # optimizing common cases.
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

  defp deep_find(list, what) when is_list(list) do
    Enum.find(list, fn x -> 
      deep_find(x, what)
    end)
  end
  defp deep_find(string, what) when is_binary(string), do: String.contains?(string, what)
  defp deep_find({_, _, list}, what), do: deep_find(list, what)
  defp deep_find(_, _), do: false

  def handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Phoenix.HTML.Engine.fetch_assign(var!(assigns), unquote(name))
    end
  end
  def handle_assign(arg), do: arg

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

  #TODO: rethink, may not be very smart
  defp plain_html(ast) do
    {_, result} = Macro.prewalk ast, [], fn node, acc ->
      case node do
        {_, _, atom} when is_atom(atom) -> {node, acc}
        {_, _, string} when is_binary(string) -> {node, [string | acc]}
        {_, _, list} -> {node, [Enum.filter(list, fn x -> is_binary(x) end) | acc]}
        _ -> {node, acc}
      end
    end
    result |> List.flatten() |> Enum.join()
  end

  # def find_unclosed_tag(list) do
  #   Enum.reduce(list, {[], []}, fn(x, {acc, closed_tags}) -> 
  #     s = String.trim_leading(x)
  #     closing_match = ~r/^\/(.*)[\s>]/
  #     opening_match = ~r/^[^\/](.*)[\s>]/
  #     # IO.inspect Regex.match?(closing_match, s)
  #     cond do
  #       Regex.match?(closing_match, s) ->
  #         # IO.puts "#{s} closing, tag: #{tag(s)}"
  #         {acc ++ ["#{x} (closing)"], closed_tags ++ [tag(s)]}
  #       Regex.match?(opening_match, s) ->
  #         # IO.puts "#{s} opening, tag: #{tag(s)}"
  #         # IO.inspect closed_tags
  #         {acc ++ ["#{x} OPEN"], closed_tags -- [tag(s)]}
  #       true -> {acc, closed_tags}
  #     end
  #     # [x] ++ acc
  #   end)
  # end

  # defp tag(string) do
  #   [_, match] = Regex.run(~r/^\/*([\S>]*)[\s>]+/, string)
  #   String.replace(match, ">", "")
  # end
end
