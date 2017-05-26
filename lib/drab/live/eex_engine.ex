defmodule Drab.Live.EExEngine do
  @moduledoc false

  import Drab.Live.Crypto
  use EEx.Engine
  require IEx

  @jsvar "__drab"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  @doc false
  def init(_opts) do
    # [engine: Drab.Live.EExEngine,
    #  file: "test/support/web/templates/live/users.html.drab", line: 1]
    init_js = "if (typeof window.#{@jsvar} == 'undefined') {window.#{@jsvar} = {}; window.#{@jsvar}.assigns = {}}"
    {:safe, ["\n", "\n", "<!-- DRAB BEGIN -->", script_tag(init_js), "\n"]}
  end

  @doc false
  def handle_body(body), do: Phoenix.HTML.Engine.handle_body(body)

  @doc false
  def handle_text({:safe, buffer}, text), do: Phoenix.HTML.Engine.handle_text({:safe, buffer}, text)

  @doc false
  def handle_text("", text), do: Phoenix.HTML.Engine.handle_text("", text)

  @doc false
  def handle_expr("", marker, expr), do: Phoenix.HTML.Engine.handle_expr("", marker, expr)

  @doc false
  def handle_expr({:safe, buffer}, "=", expr) do
    {:safe, inject_span(buffer, expr)}
  end

  @doc false
  def handle_expr({:safe, buffer}, "", expr), do: Phoenix.HTML.Engine.handle_expr({:safe, buffer}, "", expr)

  defp inject_span(buffer, expr) do
    line           = line_from_expr(expr)
    expr           = Macro.prewalk(expr, &handle_assign/1)
    encoded_expr   = encode(expr)

    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    span_begin = 
      "<span id='#{uuid()}' drab-assigns='#{found_assigns |> Enum.join(" ")}' drab-expr='#{encoded_expr}'>"
    span_end   = "</span>"
    
    # do not repeat assign javascript
    as = found_assigns |> Enum.map(fn assign ->
      # TODO: find a better way to search in buffer, rather than string-based
      if deep_find(buffer, assign_js(assign) |> List.first()) do
        []
      else
        assign_js(assign)
      end
    end) |> List.flatten()
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

  defp script_tag([]), do: []
  defp script_tag(js) do
    ["\n", "<script language='javascript'>", js, "</script>"]
  end

  defp assign_js(assign) do
    ["#{@jsvar}.assigns['#{assign}'] = '", assign_expr(assign), "';"]
  end

  defp assign_expr(assign) do
    # TODO: should not create AST directly
    assign_expr = {:@, [@anno], [{assign, [@anno], nil}]}
    assign_expr = handle_assign(assign_expr)

    {{:., [@anno], [{:__aliases__, [@anno], [:Drab, :Live, :Crypto]}, :encode]},
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
        # {:@, _, [{name, _, atom}]} when is_atom(name) and is_atom(atom) -> {node, [name | acc]} 
        # {{:., _, [_, :fetch_assign]}, _, [_, name]} when is_atom(name) -> {node, [name | acc]} 
        {{:., _, [{:__aliases__, _, [:Phoenix, :HTML, :Engine]}, :fetch_assign]}, _, [_, name]} when is_atom(name) ->
          {node, [name | acc]} 
        _ -> {node, acc}
      end
    end
    result |> Enum.uniq |> Enum.sort
  end




  # def handle_expr(buffer, "=", expr) do
  #   found_assigns = find_assigns(expr) |> Enum.join(",")
  #   expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
  #   encoded_expr = encode(expr)
  #   uuid = uuid()
  #   quote do
  #     tmp1 = unquote(buffer)
  #     # tmp1  
  #     #   <> "<span id='#{unquote(uuid)}' drab-assigns='#{unquote(found_assigns)}' drab-expr='#{unquote(encoded_expr)}'>"
  #     #   <> String.Chars.to_string(unquote(expr)) 
  #     #   <> "</span>"
  #     tmp1 
  #   end
  # end

  # def handle_expr(buffer, "", expr) do
  #   super(buffer, "", expr)
  # end

  # def handle_expr(buffer, "#", expr) do
  #   super(buffer, "", expr)
  # end




  # def init(_opts) do
  #   ""
  # end

  # def handle_expr(buffer, mark, expr) do
  #   IO.inspect expr
  #   expr = inject_drab_span(expr)
  #   IO.inspect expr
  #   expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
  #   IO.inspect expr
  #   {a, b, [e, pre_string]} = buffer
  #   # IO.inspect x
  #   # IO.inspect pre_string
  #   IO.puts ""
  #   super({a, b, [e, pre_string]}, mark, expr)
  # end

  # defp inject_drab_span(expr) do
  #   quote do 
  #     "<span>" <> unquote(expr)
  #   end
  #   # tag regex = ~r/<([^\/].*)>/mis
  #   # s = "</div1>\n<b>dwa</b><div2 dupa='bada'><i id=1>xx</i>"
  #   # l = String.split(s, ~r/</) |> Enum.reverse()
  #   # quote do
  #   #   "<drab_id>" <> unquote(expr)
  #   # end
  # end

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
