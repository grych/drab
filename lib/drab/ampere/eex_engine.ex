defmodule Drab.Ampere.EExEngine do
  @moduledoc """
  The default engine used by EEx.
  It includes assigns (like `@foo`) and possibly other
  conveniences in the future.
  ## Examples
      iex> EEx.eval_string("<%= @foo %>", assigns: [foo: 1])
      "1"
  In the example above, we can access the value `foo` under
  the binding `assigns` using `@foo`. This is useful because
  a template, after being compiled, can receive different
  assigns and would not require recompilation for each
  variable set.
  Assigns can also be used when compiled to a function:
      # sample.eex
      <%= @a + @b %>
      # sample.ex
      defmodule Sample do
        require EEx
        EEx.function_from_file :def, :sample, "sample.eex", [:assigns]
      end
      # iex
      Sample.sample(a: 1, b: 2) #=> "3"
  """

  use EEx.Engine

  def handle_expr(buffer, "=", expr) do
    IO.inspect expr
    expr = Macro.prewalk(expr, &EEx.Engine.handle_assign/1)
    IO.inspect expr
    IO.puts ""
    quote do
      tmp1 = unquote(buffer)
      tmp1 <> "<SPAN>" <> String.Chars.to_string(unquote(expr)) <> "</SPAN>"
    end
  end

  def handle_expr(buffer, "", expr) do
    super(buffer, "", expr)
  end

  def handle_expr(buffer, "#", expr) do
    super(buffer, "", expr)
  end

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
