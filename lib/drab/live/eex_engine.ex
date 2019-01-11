defmodule Drab.Live.EExEngine do
  @moduledoc """
  This is an implementation of EEx.Engine that injects `Drab.Live` behaviour.

  It parses the template during compile-time and inject Drab markers into it. Because of this,
  template must be a proper HTML. Also, there are some rules to obey, see limitations below.

  ### Limitations
  #### Avalibility of Assigns
  To make the assign avaliable within Drab, it must show up in the template with "`@assign`" format.
  Passing it to `render` in the controller is not enough.

  Also, the living assign must be inside the `<%= %>` mark. If it lives in `<% %>`, it will not be
  updated by `Drab.Live.poke/2`. This means that in the following template:

      <% local = @assign %>
      <%= local %>

  poking `@assign` will not update anything or, if `@assign` was not declared somewhere else,
  it will raise the *assign not found* exception*.

  #### Properties
  Property must be defined inside the tag, using strict `@property.path.from.node=<%= expression %>`
  syntax. One property may be bound only to the one expression, no apostrophe or double quote
  allowed.

      <button @hidden=<%= @hidden %> ...>
      <button @style.backgroundColor=<%= my_color_function(@button1) %> ...>

  Please notice that the full path to the property is allowed here, in this case the function
  is bound to `node.style.backgroundColor`.

  #### Attributes
  The attribute must be well defined, and you can't use the expression as an attribute name.

  The following is valid:

      <button class="btn <%= @button_class %>">
      <a href="<%= build_href(@site) %>">

  But following constructs are prohibited:

      <tag <%="attr='" <> @value <> "'"%>>
      <tag <%=build_attr(@name, @value)%>>

  The above will compile (with warnings), but it will not be correctly updated with
  `Drab.Live.poke`.

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
  """

  import Drab.Live.{Crypto, HTML}
  use EEx.Engine
  require IEx
  require Logger
  alias Drab.Live.{Safe, Partial, Ampere}

  @jsvar "__drab"
  @drab_id "drab-ampere"

  @anno (if :erlang.system_info(:otp_release) >= '19' do
           [generated: true]
         else
           [line: -1]
         end)

  @impl true
  def init(opts) do
    unless opts[:file]
           |> Path.basename(Drab.Config.drab_extension())
           |> Path.extname()
           |> String.downcase() == ".html" do
      raise EEx.SyntaxError,
        message: """
        Drab.Live works only with html partials.

        Invalid extention of file: #{opts[:file]}.
        """
    end

    partial = opts[:file]
    partial_hash = hash(partial)
    # Logger.info("Compiling Drab partial: #{partial} (#{partial_hash})")

    buffer = ["{{{{@drab-partial:#{partial_hash}}}}}"]
    %Safe{safe: buffer, partial: %Partial{path: partial, hash: partial_hash}}
  end

  @impl true
  def handle_body(%Safe{safe: body, partial: partial}) do
    body = List.flatten(body)
    partial_hash = partial(body)

    init_js = """
    if (typeof window.#{@jsvar} == 'undefined') {#{@jsvar}={assigns: {},nodrab: {},properties: {}}};
    if (typeof #{@jsvar}.index == 'undefined') {#{@jsvar}.index = '#{partial_hash}'};
    #{@jsvar}.assigns['#{partial_hash}'] = {};
    #{@jsvar}.nodrab['#{partial_hash}'] = {};
    """

    found_amperes = amperes_from_buffer({:safe, body})

    partial_amperes =
      for {ampere_id, values} <- found_amperes, into: %{} do
        {ampere_id,
         for {gender, tag, prop_or_attr, pattern} <- values do
           %Ampere{
             gender: gender,
             tag: tag,
             attribute: prop_or_attr,
             assigns: assigns_from_pattern(pattern)
           }
         end}
      end

    partial = %Partial{partial | amperes: partial_amperes}

    found_assigns = Partial.all_assigns(partial)

    if Drab.Live.reserved_assigns?(found_assigns) do
      raise EEx.SyntaxError,
        message: """
        trying to use Drab reserved word as an assign name. Please rename the assign.

        Reserved assign names: #{Enum.join(Drab.Live.drab_options_list(), ", ")}
        """
    end

    all_assigns = find_assigns(body)
    nodrab_assigns = all_assigns -- found_assigns

    updated_assigns =
      for assign <- found_assigns, into: %{} do
        {assign, Partial.amperes_for_assign(partial, assign)}
      end

    partial = %Partial{partial | assigns: updated_assigns}
    # if partial_hash == "gi3dcnzwgm2dcmrv" do
    #   IO.inspect(partial)
    # end

    assigns_js =
      found_assigns
      |> Enum.map(fn assign ->
        assign_js("assigns", partial_hash, assign)
      end)
      |> script_tag()

    nodrab_assigns_js =
      nodrab_assigns
      |> Enum.map(fn assign ->
        assign_js("nodrab", partial_hash, assign)
      end)
      |> script_tag()

    properies_js =
      for {ampere_id, vals} <- found_amperes do
        found_props =
          for {:prop, tag, property, pattern} <- vals do
            property_js(ampere_id, property, compiled_from_pattern(:prop, pattern, tag, property))
          end

        [
          case found_props do
            [] -> ""
            _ -> "#{@jsvar}.properties['#{ampere_id}'] = {};"
          end
          | found_props
        ]
      end
      |> script_tag()

    final =
      [
        script_tag(init_js),
        remove_drab_marks(body),
        assigns_js,
        nodrab_assigns_js,
        properies_js
      ]
      |> List.flatten()

    # can't just return %Safe{}, dialyzer would complain
    {:drab, %Safe{safe: final, partial: partial}}
  end

  @expr ~r/{{{{@drab-expr-hash:(\S+)}}}}.*{{{{\/@drab-expr-hash:\S+}}}}/Us

  @spec expr_hashes_from_pattern(String.t()) :: list
  defp expr_hashes_from_pattern(pattern) do
    for string <- String.split(pattern, @expr, include_captures: true, trim: true),
        expr = Regex.run(@expr, string),
        expr do
      List.last(expr)
    end
  end

  defp assigns_from_pattern(pattern) do
    for hash <- expr_hashes_from_pattern(pattern) do
      {_, assigns} = Process.get(hash)
      assigns
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  @spec compiled_from_pattern(atom, String.t(), String.t(), String.t()) ::
          Macro.t() | [Macro.t()] | no_return
  defp compiled_from_pattern(:prop, pattern, tag, property) do
    case compiled_from_pattern(:other, pattern, tag, property) do
      [expr | []] when is_tuple(expr) ->
        expr

      _ ->
        raise_property_syntax_error(property)
    end
  end

  defp compiled_from_pattern(_, pattern, _, _) do
    pattern
    |> String.split(@expr, include_captures: true, trim: true)
    |> Enum.map(&expr_from_cache/1)
  end

  @spec expr_from_cache(String.t()) :: Macro.t()
  defp expr_from_cache(text) do
    case Regex.run(@expr, text) do
      [_, expr_hash] ->
        {expr, _} = Process.get(expr_hash)

        quote do
          unquote(expr)
        end

      nil ->
        text
    end
  end

  @impl true
  def handle_text(%Safe{safe: buffer, partial: partial}, text) do
    q =
      quote do
        [unquote(buffer), unquote(text)]
      end

    %Drab.Live.Safe{safe: q, partial: partial}
  end

  @impl true
  def handle_text("", text) do
    handle_text(%Safe{safe: ""}, text)
  end

  @impl true
  def handle_begin(_previous) do
    %Safe{safe: ""}
  end

  @impl true
  def handle_end(%Safe{safe: safe}) do
    {:safe, safe}
  end

  @impl true
  def handle_expr("", marker, expr) do
    handle_expr(%Safe{safe: ""}, marker, expr)
  end

  @impl true
  def handle_expr(%Safe{safe: buffer, partial: partial}, "", expr) do
    expr = Macro.prewalk(expr, &handle_assign/1)

    q =
      quote do
        tmp2 = unquote(buffer)
        unquote(expr)
        tmp2
      end

    %Safe{safe: q, partial: partial}
  end

  @impl true
  def handle_expr(%Safe{safe: buffer, partial: partial}, "=", expr) do
    # check if the expression is in the nodrab/1
    {expr, nodrab} =
      case expr do
        {:nodrab, _, [only_one_parameter]} -> {only_one_parameter, true}
        _ -> {expr, false}
      end

    inject_span? = not in_opened_tag?(buffer)

    line = line_from_expr(expr)
    expr = Macro.prewalk(expr, &handle_assign/1)

    found_assigns = find_assigns(expr)
    # shallow_assigns = shallow_find_assigns(expr)
    found_assigns? = found_assigns != []

    # if the expression contains only :conn, it is always nodrab
    nodrab = if shallow_find_assigns(expr) == [:conn], do: true, else: nodrab
    # if there is no assigns, expression is nodrab by its nature
    nodrab = if found_assigns?, do: nodrab, else: true
    # also, we are not drabbing in the expression is in the comment or !DOCTYPE tag
    nodrab = if in_comment_or_doctype?(buffer), do: true, else: nodrab

    # set up parent assigns for all found children
    # unless nodrab do
    #   for child_expr_hash <- find_expr_hashes(expr) do
    #     {:expr, expression, assigns, parent_assigns} = Drab.Live.Cache.get(child_expr_hash)
    #     parent_assigns = Enum.uniq(parent_assigns ++ shallow_assigns) -- assigns
    #     Drab.Live.Cache.set(child_expr_hash, {:expr, expression, assigns, parent_assigns})
    #   end
    # end

    ampere_id = hash({partial.hash, buffer, expr})
    attribute = "#{@drab_id}=\"#{ampere_id}\""

    html = to_flat_html(buffer)

    {buffer, _ampere_id} =
      if !inject_span? && found_assigns? && !nodrab do
        case inject_attribute_to_last_opened(buffer, attribute) do
          # injected!
          {:ok, buf, amp} ->
            {buf, extract_ampere_hash(amp)}

          # it was already there
          {:already_there, _, amp} ->
            {buffer, extract_ampere_hash(amp)}

          {:not_found, _, _} ->
            raise EEx.SyntaxError,
              message: """
              can't find the parent tag for an expression in line #{line}.
              """
        end
      else
        {buffer, ampere_id}
      end

    hash = hash(expr)

    unless nodrab do
      Process.put(hash, {remove_drab_marks(expr), found_assigns})
    end

    attr = find_attr_in_html(html)
    is_property = Regex.match?(~r/<\S+/s, no_tags(html)) && attr && String.starts_with?(attr, "@")

    if is_property && !String.ends_with?(String.trim_trailing(html), "=") do
      raise_property_syntax_error(attr)
    end

    expr = if is_property, do: encoded_expr(expr), else: to_safe(expr, line)

    span_begin = "<span #{attribute}>"
    span_end = "</span>"

    expr_begin = "{{{{@drab-expr-hash:#{hash}}}}}"
    expr_end = "{{{{/@drab-expr-hash:#{hash}}}}}"

    buf =
      case {inject_span?, nodrab} do
        {_, true} ->
          # do not drab expressions with @conn only, as it is readonly
          # and when marked with nodrab()
          nodrab(buffer, expr)

        {true, _} ->
          quote do
            tmp1 = unquote(buffer)

            [
              tmp1,
              unquote(span_begin),
              unquote(expr_begin),
              unquote(expr),
              unquote(expr_end),
              unquote(span_end)
            ]
          end

        {false, _} ->
          quote do
            tmp1 = unquote(buffer)
            [tmp1, unquote(expr_begin), unquote(expr), unquote(expr_end)]
          end
      end

    # {:safe, buf}
    %Drab.Live.Safe{safe: buf, partial: partial}
  end

  @impl true
  def handle_expr(%Safe{safe: buffer, partial: partial}, "/", expr) do
    line = line_from_expr(expr)
    expr = Macro.prewalk(expr, &handle_assign/1)

    q =
      quote do
        tmp1 = unquote(buffer)
        [tmp1, unquote(to_safe(expr, line))]
      end

    %Safe{safe: q, partial: partial}
  end

  defp nodrab(buffer, expr) do
    quote do
      tmp1 = unquote(buffer)
      [tmp1, unquote(expr)]
    end
  end

  @spec partial(list) :: String.t() | nil
  defp partial(body) do
    html = to_flat_html(body)
    p = Regex.run(~r/{{{{@drab-partial:([^']+)}}}}/Uis, html)
    if p, do: List.last(p), else: nil
  end

  @spec find_attr_in_html(String.t()) :: String.t() | nil
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

  @spec args_removed(String.t()) :: String.t()
  defp args_removed(html) do
    html
    |> String.split(~r/<\S+/s)
    |> List.last()
    |> remove_full_args()
  end

  @spec remove_full_args(String.t()) :: String.t()
  defp remove_full_args(string) do
    string
    |> String.replace(~r/\S+\s*=\s*'[^']*'/s, "")
    |> String.replace(~r/\S+\s*=\s*"[^"]*"/s, "")
    |> String.replace(~r/\S+\s*=\s*[^'"\s]+\s+/s, "")
  end

  @spec take_at(list, integer) :: term
  defp take_at(list, index) do
    {item, _} = List.pop_at(list, index)
    item
  end

  @spec no_tags(String.t()) :: String.t()
  defp no_tags(html), do: String.replace(html, ~r/<\S+.*>/s, "")

  @spec script_tag(String.t() | []) :: [String.t()] | []
  defp script_tag([]), do: []

  defp script_tag(js) do
    ["<script drab-script>", js, "</script>\n"]
  end

  @spec assign_js(String.t(), String.t(), atom) :: [String.t()]
  defp assign_js(name, partial, assign) do
    ["#{@jsvar}.#{name}['#{partial}']['#{assign}'] = {document: '", encoded_assign(assign), "'};"]
  end

  @spec property_js(String.t(), String.t() | atom, Macro.t()) :: [String.t()]
  defp property_js(ampere, property, expr) do
    ["#{@jsvar}.properties['#{ampere}']['#{property}'] = ", encoded_expr(expr), ";"]
  end

  @spec encoded_assign(atom) :: Macro.t()
  defp encoded_assign(assign) do
    filter_expr =
      quote @anno do
        Drab.Live.Assign.filter(Phoenix.HTML.Engine.fetch_assign!(var!(assigns), unquote(assign)))
      end

    base64_encoded_expr(filter_expr)
  end

  @spec base64_encoded_expr(Macro.t()) :: Macro.t()
  defp base64_encoded_expr(expr) do
    quote @anno do
      Drab.Live.Crypto.encode64(unquote(expr))
    end
  end

  @doc false
  @spec encoded_expr(Macro.t()) :: Macro.t()
  defp encoded_expr(expr) do
    quote @anno do
      Drab.Core.encode_js(unquote(expr))
    end
  end

  @spec line_from_expr(Macro.t()) :: integer | nil
  defp line_from_expr({_, meta, _}) when is_list(meta), do: Keyword.get(meta, :line)
  defp line_from_expr(_), do: nil

  # @doc false
  # defp to_safe(literal), do: to_safe(literal, @anno)

  @spec to_safe(Macro.t(), integer | nil) :: iodata
  defp to_safe(literal, _line)
       when is_binary(literal) or is_atom(literal) or is_number(literal) do
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

  @spec handle_assign(Macro.t()) :: Macro.t()
  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      Phoenix.HTML.Engine.fetch_assign!(var!(assigns), unquote(name))
    end
  end

  defp handle_assign(arg), do: arg

  @spec find_assigns(Macro.t()) :: [atom]
  defp find_assigns(ast) do
    {_, result} =
      Macro.prewalk(ast, [], fn node, acc ->
        case node do
          {{:., _, [{:__aliases__, _, [:Phoenix, :HTML, :Engine]}, :fetch_assign!]}, _, [_, name]}
          when is_atom(name) ->
            {node, [name | acc]}

          _ ->
            {node, acc}
        end
      end)

    result |> Enum.uniq() |> Enum.sort()
  end

  @doc false
  @spec shallow_find_assigns(Macro.t()) :: [atom]
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

  @spec find_assign(Macro.t()) :: atom | false
  defp find_assign(
         {{:., _, [{:__aliases__, _, [:Phoenix, :HTML, :Engine]}, :fetch_assign!]}, _, [_, name]}
       )
       when is_atom(name),
       do: name

  defp find_assign(_), do: false

  defp raise_property_syntax_error(property) do
    raise EEx.SyntaxError,
      message: """
      syntax error in Drab property special form for property: #{property}

      You can only combine one Elixir expression with one node property.
      Quotes and apostrophes are not allowed.

      Allowed:

          <tag @property=<%=expression%>>

      Prohibited:

          <tag @property="<%=expression%>">
          <tag @property='<%=expression%>'>
          <tag @property="other text <%=expression%>">
          <tag @property="<%=expression1%><%=expression2%>">
      """
  end
end
