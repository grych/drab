defmodule Drab.Live.HTML do
  @moduledoc false

  @doc """
  Simple html tokenizer. Works with nested lists.

      iex> tokenize("<html> <body >some<b> anything</b></body ></html>")
      [{:tag, "html"}, {:text, " "}, {:tag, "body "}, {:text, "some"}, {:tag, "b"}, {:text, " anything"},
      {:tag, "/b"}, {:tag, "/body "}, {:tag, "/html"}, {:text, ""}]

      iex> tokenize("some")
      [{:text, "some"}]

      iex> tokenize(["some"])
      [[{:text, "some"}], {:other, []}]

      iex> tokenize("")
      [{:text, ""}]

      iex> tokenize([""])
      [[{:text, ""}], {:other, []}]

      iex> tokenize("<tag> and more")
      [{:tag, "tag"}, {:text, " and more"}]

      iex> tokenize("<tag> <naked tag")
      [{:tag, "tag"}, {:text, " "}, {:naked, "naked tag"}]

      iex> tokenize(["<tag a/> <naked tag"])
      [[{:tag, "tag a/"}, {:text, " "}, {:naked, "naked tag"}], {:other, []}]

      iex> tokenize(["other", "<tag a> <naked tag"])
      [[{:text, "other"}], [{:tag, "tag a"}, {:text, " "}, {:naked, "naked tag"}], {:other, []}]

      iex> tokenize(["other", :atom, "<tag a/> <naked tag"])
      [[{:text, "other"}], :atom, [{:tag, "tag a/"}, {:text, " "}, {:naked, "naked tag"}], {:other, []}]

      iex> tokenize(["<tag", :atom, ">"])
      [[naked: "tag"], :atom, [{:text, ">"}], {:other, []}]
  """
  def tokenize("") do
    [{:text, ""}]
  end
  def tokenize("<" <> rest) do
    case String.split(rest, ">", parts: 2) do
      [tag] -> [{:naked, String.trim_leading(tag)}] # naked tag can be only at the end
      [tag | tail] -> [{:tag, String.trim_leading(tag)} | tokenize(Enum.join(tail))]
    end
  end
  def tokenize(string) when is_binary(string) do
    case String.split(string, "<", parts: 2) do
      [no_more_tags] -> [{:text, no_more_tags}]
      [text, rest] -> [{:text, text} | tokenize("<" <> rest)]
    end
  end
  def tokenize({code, meta, args}) do
    {code, meta, tokenize(args)}
  end
  def tokenize([]) do
    [{:other, []}]
  end
  def tokenize([head | tail]) do
    [tokenize(head) | tokenize(tail)]
  end
  def tokenize(other) do
    other
  end

  @doc """
  Detokenizer. Leading spaces in the tags are removed! (< html> becomes <html>).

      iex> html = "<html> <body >some<b> anything</b></body ></html>"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "text"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ""
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = []
      iex> html |> tokenize() |> tokenized_to_html()
      []

      iex> html = [""]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "<tag> <naked tag"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "<  tag> < naked tag"
      iex> html |> tokenize() |> tokenized_to_html()
      "<tag> <naked tag"

      iex> html = ["other", "<tag a> <naked tag"]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["other", "<t>a</t>", "<tag a> <naked tag"]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["other", ["<t>a</t>", "<tag a> <naked tag"]]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["other", [["<t>a</t>"], "<tag a> </tag>"]]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["other", :atom, "<tag a> </tag>"]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["other", [:atom, "<tag a> </tag>"]]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> tok = [["other"], [:atom, [{:tag, "tag a"}, " ", {:tag, "/tag"}], {:other}]]
      iex> tokenized_to_html(tok)
      ["other", [:atom, "<tag a> </tag>", {:other}]]

      iex> tok = [[naked: "tag"], :atom, [">"]]
      iex> tokenized_to_html(tok)
      ["<tag", :atom, ">"]
  """
  # def tokenized_to_html([:empty]), do: []
  # def tokenized_to_html(:empty), do: ""
  def tokenized_to_html([{:other, []}]), do: []
  def tokenized_to_html({:other, []}), do: ""
  def tokenized_to_html([]), do: ""
  def tokenized_to_html({:tag, tag}), do: "<#{tag}>"
  def tokenized_to_html({:naked, tag}), do: "<#{tag}"
  def tokenized_to_html({:text, text}), do: text
  def tokenized_to_html({code, meta, args}), do: {code, meta, tokenized_to_html(args)}
  def tokenized_to_html(text) when is_binary(text), do: text
  def tokenized_to_html(atom) when is_atom(atom), do: atom
  def tokenized_to_html({atom, list}) when is_atom(atom) and is_list(list), do: {atom, tokenized_to_html(list)}
  def tokenized_to_html([list]) when is_list(list), do: [tokenized_to_html(list)]
  # def tokenized_to_html([head | tail]) when is_list(head) and is_list(tail), do: [tokenized_to_html(head) | tokenized_to_html(tail)]
  def tokenized_to_html([head | tail]) do
    # t = tokenized_to_html(tail)
    # case tokenized_to_html(head) do
    #   h when is_binary(h) and is_binary(t) -> h <> t
    #   h -> if t == "", do: [h], else: [h | t]
    # end
    case {tokenized_to_html(head), tokenized_to_html(tail)} do
      {h, t} when is_binary(h) and is_binary(t) -> h <> t
      {h, ""} -> [h]
      {h, t} when not is_list(t) -> [h, t]
      {h, t} -> [h | t]
    end
  end
  def tokenized_to_html(other), do: other

  @doc """
  Injects given attribute to the last found opened (or naked) tag.

    iex> inject_attribute_to_last_opened "<tag>", "attr=1"
    {:ok, "<tag attr=1>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag attr2>", "attr=1"
    {:ok, "<tag attr=1 attr2>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag attr2><tag></tag>", "attr=1"
    {:ok, "<tag attr=1 attr2><tag></tag>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag></tag><tag attr2", "attr=1"
    {:ok, "<tag></tag><tag attr=1 attr2", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag><tag attr2", "attr=1"
    {:ok, "<tag><tag attr=1 attr2", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag><tag attr2>", "attr=1"
    {:ok, "<tag><tag attr=1 attr2>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag><hr/><tag attr2></tag>", "attr=1"
    {:ok, "<tag attr=1><hr/><tag attr2></tag>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag><br><tag attr2></tag>", "attr=1"
    {:ok, "<tag attr=1><br><tag attr2></tag>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag><tag></tag>", "attr=1"
    {:ok, "<tag attr=1><tag></tag>", "attr=1"}

    iex> inject_attribute_to_last_opened "<img src", "attr=1"
    {:ok, "<img attr=1 src", "attr=1"}

    iex> inject_attribute_to_last_opened "<hr>", "attr=1"
    {:not_found, "<hr>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag>", "attr=1"
    {:ok, "<tag 1><tag attr=1 2><tag 3></tag>", "attr=1"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag></tag>", "attr='3'"
    {:ok, "<tag attr='3' 1><tag 2><tag 3></tag></tag>", "attr='3'"}

    iex> inject_attribute_to_last_opened "<tag 1></tag>", "attr=x"
    {:not_found, "<tag 1></tag>", "attr=x"}

    iex> inject_attribute_to_last_opened "text only", "attr=x"
    {:not_found, "text only", "attr=x"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag></tag></tag>", "attr=x"
    {:not_found, "<tag 1><tag 2><tag 3></tag></tag></tag>", "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2><tag 3></tag>", "</tag>"], "attr=x"
    {:ok, ["<tag attr=x 1><tag 2><tag 3></tag>", "</tag>"], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2><tag 3></tag>", :atom, "</tag>"], "attr=x"
    {:ok, ["<tag attr=x 1><tag 2><tag 3></tag>", :atom, "</tag>"], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", "text", "<tag 3></tag>", "</tag>"], "attr=x"
    {:ok, ["<tag attr=x 1><tag 2>", "text", "<tag 3></tag>", "</tag>"], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", ["<tag 3>", "</tag>"]], "attr=x"
    {:ok, ["<tag 1><tag attr=x 2>", ["<tag 3>", "</tag>"]], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", {:other}, ["<tag 3>", "</tag>"]], "attr=x"
    {:ok, ["<tag 1><tag attr=x 2>", {:other}, ["<tag 3>", "</tag>"]], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", {}, ["<tag 3>", :atom, "</tag>", {}]], "attr=x"
    {:ok, ["<tag 1><tag attr=x 2>", {}, ["<tag 3>", :atom, "</tag>", {}]], "attr=x"}

    iex> inject_attribute_to_last_opened ["<tag attr=42 1><tag 2><tag 3></tag>", "</tag>"], "attr=x"
    {:already_there, ["<tag attr=42 1><tag 2><tag 3></tag>", "</tag>"], "attr=42"}

    iex> inject_attribute_to_last_opened "<img attr=2 src", "attr=1"
    {:already_there, "<img attr=2 src", "attr=2"}
  """
  def inject_attribute_to_last_opened(buffer, attribute) when is_tuple(buffer) do
    # in case when there is no text between expressions
    {result, [acc], attribute} = inject_attribute_to_last_opened([buffer], attribute)
    {result, acc, attribute}
  end

  def inject_attribute_to_last_opened(buffer, attribute) do
    {_, found, acc} = buffer
      |> tokenize()
      |> deep_reverse()
      |> do_inject(attribute, [], :not_found, [])
    acc = acc |> deep_reverse() |> tokenized_to_html()

    case found do
      result when is_atom(result) -> {result, acc, attribute}
      result when is_binary(result) -> {:already_there, acc, result}
    end
  end

  @non_closing_tags ~w{
    area base br col embed hr img input keygen link meta param source track wbr
    area/ base/ br/ col/ embed/ hr/ img/ input/ keygen/ link/ meta/ param/ source/ track/ wbr/
  }
  #TODO: refactor, must be a simpler way to do it
  defp do_inject([], _, opened, found, acc) do
    {opened, found, acc}
  end
  defp do_inject([head | tail], attribute, opened, found, acc) do
    case head do
      {:tag, "/" <> tag} ->
        # IO.puts "closing"
        do_inject(tail, attribute, [tag_name(tag) | opened], found, acc ++ [head])
      {tag_type, tag} when tag_type in [:naked, :tag] ->
        # IO.puts "TAG"
        if Enum.find(opened, fn x -> tag_name(tag) == x end) do
          do_inject(tail, attribute, opened -- [tag_name(tag)], found, acc ++ [head])
        else
          if found != :not_found || (tag_type != :naked && Enum.member?(@non_closing_tags, tag_name(tag))) do
            do_inject(tail, attribute, opened, found, acc ++ [head])
          else
            {result, injected} = case find_attribute(tag, attribute) do
              nil -> {:ok, {tag_type, add_attribute(tag, attribute)}}
              found_attr -> {found_attr, head}
            end
            do_inject(tail, attribute, opened, result, acc ++ [injected])
          end
        end
      {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | buffer]} | rest]} ->
        # IO.puts "BUFFER"
        {op, fd, ac} = do_inject(buffer, attribute, opened, found, [])
        # IO.inspect ac
        modified_buffer = {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | ac]} | rest]}
        do_inject(tail, attribute, op, fd, acc ++ [modified_buffer])
      list when is_list(list) ->
        # IO.puts "LIST"
        {op, fd, modified_buffer} = do_inject(list, attribute, opened, found, [])
        do_inject(tail, attribute, op, fd, acc ++ [modified_buffer])
      _ ->
        # IO.puts "OTHER"
        do_inject(tail, attribute, opened, found, acc ++ [head])
    end
  end

  defp tag_name(tag) do
    String.split(tag, ~r/\s/) |> List.first()
  end

  @doc """
  Add attribute to a tag.

      iex> add_attribute("tag tag=2", "attr=1")
      "tag attr=1 tag=2"
  """
  def add_attribute(tag, attribute) do
    String.replace(tag, tag_name(tag), "#{tag_name(tag)} #{attribute}", global: false)
  end

  @doc """
  Find an existing attribute

      iex> find_attribute("tag attrx=1 attr='2' attra=4", "attr=3")
      "attr='2'"

      iex> find_attribute("tag attrx=1 attra=4", "attr=3")
      nil

      iex> find_attribute("tag ", "attr=3")
      nil

      iex> find_attribute("tag attrx = 1 attr = '2' attra= 4 ", "attr = 3")
      "attr='2'"
  """
  def find_attribute(tag, attr) do
    [attr_name | _] = attr
      |> trim_attr()
      |> String.split("=", parts: 2)
    # attr_name = String.trim(attr_name)

    case Regex.run(~r/(#{attr_name}\s*=\s*\S+)/, tag, capture: :first) do
      [att] -> trim_attr(att)
      other -> other
    end
  end

  defp trim_attr(attr) do
    [attr_name, attr_value] = String.split(attr, "=", parts: 2)
    attr_name = String.trim(attr_name)
    attr_value = String.trim(attr_value)
    attr_name <> "=" <> attr_value
  end

  @doc """
  Converts buffer to html. Nested expressions are ignored.
  """
  def to_flat_html({:safe, body}), do: to_flat_html(body)
  def to_flat_html(body), do: do_to_flat_html(body) |> List.flatten() |> Enum.join()

  defp do_to_flat_html([]), do: []
  defp do_to_flat_html(body) when is_binary(body), do: [body]
  # tmp1 is in generating output expression <%= %>
  defp do_to_flat_html({:__block__, [], [{:=, [], [{:tmp1, [], Drab.Live.EExEngine} | buffer]} | rest]}) do
    do_to_flat_html(buffer) ++ do_to_flat_html(rest)
  end
  # while tmp2 inidcates the expression inside <% %>
  defp do_to_flat_html({:__block__, [], [{:=, [], [{:tmp2, [], Drab.Live.EExEngine} | buffer]} | _]}) do
    do_to_flat_html(buffer)
  end
  defp do_to_flat_html([head | rest]), do: do_to_flat_html(head) ++ do_to_flat_html(rest)
  defp do_to_flat_html({_, _, list}) when is_list(list), do: do_to_flat_html(list)
  defp do_to_flat_html({_, _, _}), do: []
  defp do_to_flat_html(atom) when is_atom(atom), do: []
  defp do_to_flat_html({_, buffer}), do: do_to_flat_html(buffer)
  defp do_to_flat_html(_), do: []  # TODO: rething, may be insecure

  @doc """
  Returns true if the expression is directly under the opened tag

      iex> in_opened_tag? ["<tag 1><tag 2>", ["<tag 3>", "</tag 3> x"]]
      false
      iex> in_opened_tag? ["<tag 1><tag 2> x", ["<tag 3> xx"]]
      true
      iex> in_opened_tag? ["anything else"]
      false
      iex> in_opened_tag? []
      false
      iex> in_opened_tag? ""
      false
      iex> in_opened_tag? ["<tag 1><tag 2> x"]
      true
      iex> in_opened_tag? ["<tag 1></tag 2> x <br x> x"]
      false
      iex> in_opened_tag? ["<tag 1></tag 2> x <br x"]
      true
      iex> in_opened_tag? ["<tag 1><tag2 x"]
      true
      iex> in_opened_tag? "<tag2 a=x x=' "
      true
      iex> in_opened_tag? "<input type='text' value='"
      true
  """
  def in_opened_tag?({:safe, body}), do: in_opened_tag?(body)
  def in_opened_tag?(body) do
    tokenized =
      body
      |> to_flat_html()
      |> tokenize()
    case last_tag(tokenized) do
      {_, tag} -> not String.starts_with?(tag, "/")
      nil -> false
    end
  end

  defp last_tag(tokenized) do
    tokenized
      |> Enum.filter(fn
            {:naked, _} -> true
            {:tag, x} -> not (tag_name(x) in @non_closing_tags)
            _ -> false
         end)
      |> Enum.reverse()
      |> Enum.find(&(match?({_, _}, &1)))
  end

  @doc """
  Returns amperes and patterns from flat html.
  Pattern is processed by Floki, so it doesn't have to be the same as original!
  """
  def amperes_from_buffer({:safe, buffer}) when is_list(buffer) do
    amperes_from_html(to_flat_html(buffer))
      |> Map.merge(amperes_from_buffer(buffer))
  end
  def amperes_from_buffer([]) do
    %{}
  end
  def amperes_from_buffer([{atom, _, args} | tail]) when is_atom(atom) and is_list(args) do
    Map.merge(amperes_from_buffer(args), amperes_from_buffer(tail))
  end
  def amperes_from_buffer([head | tail]) do
    case head do
      [{key, value}] when is_atom(key) -> Map.merge(amperes_from_buffer(tail), amperes_from_buffer(value))
      _ -> amperes_from_buffer(tail)
    end
  end
  def amperes_from_buffer({atom, _, args}) when is_atom(atom) and is_list(args) do
    amperes_from_buffer(args)
  end
  def amperes_from_buffer({atom, _, _}) when is_atom(atom) do
    %{}
  end
  def amperes_from_buffer({tuple, _, _}) when is_tuple(tuple) do
    amperes_from_buffer(tuple)
  end
  # def amperes_from_buffer(_) do
  #   %{}
  # end

  defp amperes_from_html(list) when is_list(list), do: amperes_from_html(to_flat_html(list))
  defp amperes_from_html(html) when is_binary(html) do
    with_amperes = html
      |> Floki.parse()
      |> Floki.find("[drab-ampere]")
    for {tag, attributes, inner_html} <- with_amperes, into: Map.new() do
      ampere = find_ampere(attributes)
      html_part = if contains_expression?(inner_html), do: [{:html, tag, "innerHTML", Floki.raw_html(inner_html)}], else: []
      attrs_part = for {attr_name, attr_pattern} <- attributes, contains_expression?(attr_pattern) do
        case attr_name do
          "@" <> prop_name -> {:prop, tag, case_sensitive_prop_name(html, ampere, prop_name), attr_pattern}
          _ -> {:attr, tag, attr_name, attr_pattern}
        end
      end
      {ampere, html_part ++ attrs_part}
    end
  end

  @doc """
  Finds a real property name (case sensitive), based on the attribute (lowercased) name
  """
  def case_sensitive_prop_name(html, ampere, prop_name) do
    {:tag, body} = html
    |> tokenize()
    |> Enum.find(
      fn x ->
        case x do
          {:tag, tag} -> String.contains?(tag, "drab-ampere=\"#{ampere}\"")
          _ -> false
        end
      end)
    [_, property] = Regex.run(~r/@(#{prop_name})\s*=/i, body)
    property
  end

  defp find_ampere(attributes) do
    {_, ampere} = Enum.find attributes, fn {name, _} -> name == "drab-ampere" end
    ampere
  end

  @expr_begin ~r/{{{{@drab-expr-hash:\S+}}}}/
  @expr_end   ~r/{{{{\/@drab-expr-hash:\S+}}}}/
  @partial    ~r/{{{{@drab-partial:\S+}}}}/
  defp contains_expression?(html) when is_binary(html) do
    Regex.match?(@expr_begin, html)
  end
  defp contains_expression?(html) do
    html |> Floki.raw_html() |> contains_expression?()
  end

  @doc """
  Removes all Drab's marks from the buffer
  """
  def remove_drab_marks({:safe, buffer}) do
    {:safe, remove_drab_marks(buffer)}
  end
  def remove_drab_marks(buffer) do
    Macro.prewalk buffer, fn
      text when is_binary(text) ->
        text
        |> String.replace(@expr_begin, "", global: true)
        |> String.replace(@expr_end, "", global: true)
        |> String.replace(@partial, "", global: true)
      x ->
        x
    end
  end
  # def remove_drab_marks([]) do
  #   []
  # end
  # def remove_drab_marks([head | tail]) when is_binary(head) do
  #   if Regex.match?(@expr_begin, head) || Regex.match?(@expr_end, head) || Regex.match?(@partial, head) do
  #     [remove_drab_marks(head) | remove_drab_marks(tail)]
  #   else
  #     [head | remove_drab_marks(tail)]
  #   end
  # end
  # def remove_drab_marks([[{atom, args}] | tail]) when is_atom(atom) do
  #   [[{atom, remove_drab_marks(args)}] | remove_drab_marks(tail)]
  # end
  # def remove_drab_marks([head | tail]) when is_atom(head) do
  #   [head | remove_drab_marks(tail)]
  # end
  # def remove_drab_marks([head | tail]) when is_list(head) do
  #   [remove_drab_marks(head) | remove_drab_marks(tail)]
  # end
  # def remove_drab_marks([{atom, meta, args} | tail]) when is_list(args) do
  #   [{atom, meta, remove_drab_marks(args)} | remove_drab_marks(tail)]
  # end
  # def remove_drab_marks([{atom, meta, args} | tail]) when is_atom(args) do
  #   [{atom, meta, args} | remove_drab_marks(tail)]
  # end
  # def remove_drab_marks({atom, meta, args}) when is_list(args) do
  #   {atom, meta, remove_drab_marks(args)}
  # end
  # def remove_drab_marks({atom, meta, args}) when is_atom(args) do
  #   {atom, meta, args}
  # end
  # # def remove_drab_marks(tuple) when is_tuple(tuple) do
  # #   tuple
  # # end
  # def remove_drab_marks(text) when is_binary(text) do
  #   text
  #   |> String.replace(@expr_begin, "", global: true)
  #   |> String.replace(@expr_end, "", global: true)
  #   |> String.replace(@partial, "", global: true)
  # end
  # def remove_drab_marks(list) when is_list(list) do
  #   list
  # end
  # def remove_drab_marks(nil) do
  #   []
  # end
  # def remove_drab_marks(atom) when is_atom(atom) do
  #   atom
  # end
  # # def remove_drab_marks(other) do
  # #   other
  # # end

  @doc """
  Deep reverse of the list

      iex> deep_reverse [1,2,3]
      [3,2,1]

      iex> deep_reverse [[1,2],[3,4]]
      [[4,3], [2,1]]

      iex> deep_reverse [[[1,2], [3,4]], [5,6]]
      [[6,5], [[4,3], [2,1]]]

      iex> deep_reverse [1, [2, 3], 4]
      [4, [3, 2], 1]
  """
  def deep_reverse(list) do
    list |> Enum.reverse() |> Enum.map(fn
      {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | buffer]} | rest]} ->
        {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | deep_reverse(buffer)]} | deep_reverse(rest)]}
      x when is_list(x) ->
        deep_reverse(x)
      x ->
        x
    end)
  end
end
