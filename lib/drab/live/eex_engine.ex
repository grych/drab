defmodule Drab.Live.EExEngine do
  @moduledoc false

  import Drab.Live.Crypto
  use EEx.Engine
  require IEx

  @jsvar "__drab"
  @drab_indicator  "__drabbed"

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
    html = get_plain_html(buffer) 
    if Regex.match?(~r/<\S+/, no_tags(html)) do
      # raise """
      # Live Expressions inside tags are not allowed yet
      # """
      {:safe, inject_attribute(buffer, expr, html)}
    else
      {:safe, inject_span(buffer, expr)}
    end
  end

  defp inject_attribute(buffer, expr, html) do
    line           = line_from_expr(expr)
    expr           = Macro.prewalk(expr, &handle_assign/1)
    expr_hash      = hash(expr)
    Drab.Live.Cache.add(expr_hash, expr)

    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    # do not repeat assign javascript
    as = deduplicated_js_lines(buffer, found_assigns)
    assigns_js = script_tag(as)

    #TODO: try to find out if there is nothing AFTER the expression? I guess not
    # IO.inspect html
    # Regex.match?(~r/__dumb=".+"/, html) && invalid_attribute!(line)
    opener = String.last(html)
    closer = case opener do
      "\"" -> "#{@drab_indicator}=\""
      "'"  -> "#{@drab_indicator}='"
      "="  -> "#{@drab_indicator}"
      _    -> invalid_attribute!(line)
    end

    {attribute, _} = String.split(no_tags(html), ~r/[=\s]/) |> List.pop_at(-2)
    unless attribute, do: invalid_attribute!(line)

    opener = if opener == "=", do: "", else: opener

    expr_assigns = "drab-assigns-#{expr_hash}='#{found_assigns |> Enum.join(" ")}'"
    expr_attribute = "drab-attribute-#{expr_hash}='#{attribute}'"

    attr = "#{opener} #{expr_assigns} #{expr_attribute} #{closer}"

    if found_assigns? do
      quote do
        [unquote(assigns_js), unquote(buffer), unquote(to_safe(expr, line)), unquote(attr)]
      end
    else
      quote do
        [unquote(buffer), unquote(to_safe(expr, line))]
      end
    end
  end

  defp inject_span(buffer, expr) do
    line           = line_from_expr(expr)
    expr           = Macro.prewalk(expr, &handle_assign/1)
    expr_hash      = hash(expr)
    Drab.Live.Cache.add(expr_hash, expr)

    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []
    drab_assigns   = found_assigns |> Enum.join(" ")

    span_begin = 
      "<span id='#{uuid()}' drab-assigns='#{drab_assigns}' drab-expr='#{expr_hash}' #{@drab_indicator}='ampere'>"
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

  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/, "")

  defp invalid_attribute!(line) do
    raise """
      Invalid attribute in html template, line: #{line}.
      Partials or mixing expression in HTML tag attributes are not allowed. Use only:
        <tag attribute="<%= my_func() %>">
        <tag attribute='<%= @attr <> @attr2 %>'>
        <tag attribute=<%= my_func(@attr) %>>
      """    
  end

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
    result |> Enum.uniq |> Enum.sort
  end

  #TODO: rethink, may not be very smart
  def get_plain_html(ast) do
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

  def find_unclosed_tag(list) do
    Enum.reduce(list, {[], []}, fn(x, {acc, closed_tags}) -> 
      s = String.trim_leading(x)
      closing_match = ~r/^\/(.*)[\s>]/
      opening_match = ~r/^[^\/](.*)[\s>]/
      # IO.inspect Regex.match?(closing_match, s)
      cond do
        Regex.match?(closing_match, s) ->
          # IO.puts "#{s} closing, tag: #{tag(s)}"
          {acc ++ ["#{x} (closing)"], closed_tags ++ [tag(s)]}
        Regex.match?(opening_match, s) ->
          # IO.puts "#{s} opening, tag: #{tag(s)}"
          IO.inspect closed_tags
          {acc ++ ["#{x} OPEN"], closed_tags -- [tag(s)]}
        true -> {acc, closed_tags}
      end
      # [x] ++ acc
    end)
  end

  defp tag(string) do
    [_, match] = Regex.run(~r/^\/*([\S>]*)[\s>]+/, string)
    String.replace(match, ">", "")
  end
end
