defmodule Drab.Live.EExEngine do
  @moduledoc """

  """

  import Drab.Live.Crypto
  use EEx.Engine
  require IEx

  @jsvar           "__drab"
  @drab_indicator  "drabbed"
  @start_script    ~r/<script[^<>]*>/i
  @end_script      ~r/<\/script[^<>]*>/i
  @script_id       "drab-script"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
    [generated: true]
  else
    [line: -1]
  end)

  #TODO: like this, will not work with parallel compiling
  defp start_shadow_buffer(initial) do 
    agent = :drab_compile_agent
    case Agent.start_link(fn -> initial end, name: agent) do
      {:ok, _} = ret -> 
        ret
      {:error, {:already_started, _}} ->
        raise EEx.SyntaxError, message: """
          Exprected unexprected.
          Shadow buffer Agent already started. Please report it as a bug in https://github.com/grych/drab
          """
    end
  end

  defp stop_shadow_buffer() do
    :drab_compile_agent |> Agent.stop()
  end

  defp put_shadow_buffer(content) do 
    agent = :drab_compile_agent
    Agent.update(agent, &[content | &1]) 
    # Agent.update(agent, fn _ -> content end) 
  end

  defp get_shadow_buffer() do 
    agent = :drab_compile_agent
    Agent.get(agent, &(&1)) |> Enum.reverse |> Enum.join()
  end


  @doc false
  def init(opts) do
    # [engine: Drab.Live.EExEngine,
    #  file: "test/support/web/templates/live/users.html.drab", line: 1]
    # {:ok, var!(shadow_buffer, Drab.Live.EExEngine)} = start_shadow_buffer([])
    IO.puts "\n\nINIT #{inspect opts}"
    buffer = ["\n<span drab-partial='#{opts[:file]}'>\n"]
    start_shadow_buffer(buffer)
    {:safe, buffer}
  end

  def collect_scripts([], opened_no) do
    [{[], opened_no}]
  end
  def collect_scripts([h | t], opened_no) do
    collect_scripts(h, opened_no) ++ collect_scripts(t, opened_no)
    # Enum.map(buffer, fn b ->
    #   collect_scripts(b, opened_no)
    # end)
  end
  def collect_scripts(buffer, opened_no) when is_binary(buffer) do
    cond do
      Regex.match?(~r/<script/i, buffer) -> 
        [{buffer, opened_no + 1}]
      Regex.match?(~r/<\/script/i, buffer) -> 
        [{buffer, opened_no - 1}]
      true ->
        # collect_scripts([], opened_no)
        [{}]
    end
  end
  def collect_scripts({:|, _, list}, opened_no) do
    collect_scripts(list, opened_no)
  end
  def collect_scripts({atom, x, args} = tuple, 0) when is_tuple(tuple) do
    collect_scripts(args, 0)
  end
  def collect_scripts({atom, x, args} = tuple, opened_no) when is_tuple(tuple) do
    # IO.inspect "FOUND TUPEL"
    # collect_scripts([], acc ++ [{:tupppppppleeee, tuple}], opened_no)
    {tuple, opened_no}
  end
  def collect_scripts(other, opened_no)  do
    # collect_scripts(other, opened_no)
    # {opened_no}
    [{[], opened_no}]
  end

  defp partial(body) do
    html = to_html(body)
    [_, p] = Regex.run ~r/<span drab-partial='([^']+)'/, html
    p |> String.to_atom()
  end

  defp to_html(body), do: do_to_html(body) |> List.flatten() |> Enum.join()

  defp do_to_html([]), do: []
  defp do_to_html(body) when is_binary(body), do: [body]
  defp do_to_html({_, _, list}) when is_list(list), do: do_to_html(list)
  defp do_to_html([head | rest]), do: do_to_html(head) ++ do_to_html(rest)
  defp do_to_html(_), do: []

  @doc false
  def handle_body({:safe, body}) do 
    # html = to_html(body)
    # IO.puts ""
    # IO.puts ""
    # IO.inspect find_assigns(body)
    # IO.inspect partial(body)
    # IO.inspect body

    found_assigns = find_assigns(body)
    assigns_js = deduplicated_js_lines(body, found_assigns) |> script_tag()

    init_js = "if (typeof window.#{@jsvar} == 'undefined') {window.#{@jsvar} = {}; window.#{@jsvar}.assigns = {}}"
    final = [script_tag(init_js), assigns_js, body, "\n</span>\n"]

    put_shadow_buffer("\n</span>\n")
    Drab.Live.Cache.set({:shadow, partial(body)}, get_shadow_buffer() |> Floki.parse())
    stop_shadow_buffer()

    {:safe, final}
  end

  @doc false
  def handle_text({:safe, buffer}, text) do
    put_shadow_buffer(text)
    {:safe, quote do
      [unquote(buffer)|unquote(text)]
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
    put_shadow_buffer(shadow)
    {:safe, injected}
  end

  defp in_script?(html) do
    # true if the expression is in <script></script>
    count_matches(html, @start_script) > count_matches(html, @end_script)
  end

  defp count_matches(html, regex) do
    regex |> Regex.scan(html) |> Enum.count()
  end

  defp replace_in(string, tag) when is_binary(string) do
    if String.contains?(string, @script_id) do
      string
    else
      # IO.inspect replace_last(string, find, replacement)
      replacement = "<#{tag} #{@script_id}='#{uuid()}'"
      replace_last(string, "<#{tag}", replacement)
    end
  end

  #TODO: should really replace only last occurence in the whole nested list
  # now it assigns id to the innocent scripts
  defp replace_in(list, tag) when is_list(list) do
    Enum.map(list, fn x -> replace_in(x, tag) end)
  end

  defp replace_in(other, _), do: other

  defp inject_drab_id(buffer, tag) do
    Macro.prewalk(buffer, fn expr -> 
      case expr do
        {:|, x, list} ->
          {:|, x, replace_in(list, tag)}
        other -> other
      end
    end)
  end

  # find the drab id in the last tag
  defp drab_id(html, tag) do
    r = ~r/<#{tag}[^<>]*#{@script_id}\s*=\s*'(.*)'[^<>]*>/isU
    # IO.inspect Regex.scan(r, html)
    Regex.scan(r, html) |> List.last() |> List.last()
    # IO.inspect html
  end


  # The expression is inside the <script> tag
  defp inject_script(buffer, expr, line) do
    # IO.puts ""
    # IO.puts "IN SCRIPT"


    found_assigns  = find_assigns(expr)
    found_assigns? = (found_assigns != [])

    # Poniższe dziala, ale będzie nowe podejście
    # buffer = inject_drab_id(buffer, "script")
    # html = to_html(buffer) 

    # drab_id = drab_id(html, "script")
    # Drab.Live.Cache.add(drab_id, {:script, expr, found_assigns})

    # assigns_js = deduplicated_js_lines(buffer, found_assigns) |> script_tag()

    # if found_assigns? do
    #   quote do
    #     [unquote(assigns_js), unquote(buffer), unquote(to_safe(expr, line))]
    #   end
    # else 
      {quote do
        [unquote(buffer) | unquote(to_safe(expr, line))]
      end, "{{{{@script}}}}"}
    # end
    
  end

  # Easy way. Surroud the expression with Drab Span
  defp inject_span(buffer, expr, line) do
    found_assigns  = find_assigns(expr)
    found_assigns? = found_assigns != []

    hash = hash({:ampere, expr, found_assigns})
    Drab.Live.Cache.set(hash, {:ampere, expr, found_assigns})

    span_begin = "<span drab-expr='#{hash}'>"
    span_end   = "</span>"

    # do not repeat assign javascript
    # assigns_js = deduplicated_js_lines(buffer, found_assigns) |> script_tag()

    buf = if found_assigns? do
      quote do
        [unquote(buffer), 
        unquote(span_begin),
        unquote(to_safe(expr, line)),
        unquote(span_end)]
      end
    else 
      quote do
        [unquote(buffer) | unquote(to_safe(expr, line))]
      end
    end

    {buf, "{{{{@span}}}}"}
  end

  # The expression is inside the attribute
  # In this case we need to inject the attribute, `drab-attr-HASH`, refering to the tuple in the Cache,
  # which contains expression, assigns and the attribute name
  defp inject_attribute(buffer, expr, _html, line) do
    # line           = line_from_expr(expr)
    # expr           = Macro.prewalk(expr, &handle_assign/1)

    found_assigns  = find_assigns(expr) |> Enum.sort()
    # found_assigns? = found_assigns != []

    # do not repeat assign javascript
    # assigns_js = deduplicated_js_lines(buffer, found_assigns) |> script_tag()

    lastline = last_line(buffer)
    attribute = find_attr_in_line(lastline)
    prefix = find_prefix_in_line(lastline)

    hash = hash({:attributed, expr, found_assigns, attribute})
    Drab.Live.Cache.set(hash, {:attributed, expr, found_assigns, attribute, prefix})

    # Add drabbed indicator, only once
    drabbed = if Regex.match?(~r/<\S+/, lastline), do: "#{@drab_indicator} ", else: ""

    # Add Drab Attribute just before the attribute
    injected_line =
      replace_last(lastline, attribute, "#{drabbed}drab-attr-#{hash} #{attribute}")

    # Hack the buffer by replacing the last line
    [{a, b, list}] = buffer
    buffer = [{a, b, List.replace_at(list, -1, injected_line)}]

    # buf = if found_assigns? do
    buf = quote do
        # [unquote(assigns_js), unquote(buffer), unquote(to_safe(expr, line)), unquote(attr)]
        [unquote(buffer) | unquote(to_safe(expr, line))]
      end
    # else
    #   quote do
    #     [unquote(buffer) | unquote(to_safe(expr, line))]
    #   end
    # end

    {buf, "{{{{@attribute}}}}"}
  end

  @doc false
  def find_attr_in_line(line) do
    args_removed = line
    |> String.split(~r/<\S+/)
    |> take_at(-1)
    |> remove_full_args()

    unless String.contains?(args_removed, "=") do
      raise EEx.SyntaxError, message: """
        Invalid attribute in html template:
          `#{inspect line}`
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

  @doc false
  def find_prefix_in_line(line) do
    line
    |> String.split("=") 
    |> take_at(-1)
    |> String.replace(~r/^\s*["']*/, "", global: false)
    |> String.replace_suffix("'", "")
    |> String.replace_suffix("\"", "")
  end

  def remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/, "")
  end

  defp replace_last(string, pattern, replacement) do
    # String.reverse(string)
    # |> String.replace(String.reverse(pattern), String.reverse(replacement), global: false) 
    # |> String.reverse()
    String.replace(string, ~r/#{pattern}(?!.*#{pattern})/is, replacement)
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
    ["<script>", js, "</script>"]
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
  # defp to_html(ast) do
  #   {_, result} = Macro.prewalk ast, [], fn node, acc ->
  #     case node do
  #       {_, _, atom} when is_atom(atom) -> {node, acc}
  #       {_, _, string} when is_binary(string) -> {node, [string | acc]}
  #       {_, _, list} -> {node, [Enum.filter(list, fn x -> is_binary(x) end) | acc]}
  #       _ -> {node, acc}
  #     end
  #   end
  #   result |> List.flatten() |> Enum.join()
  # end

end
