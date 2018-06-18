defmodule Drab.Live.HTML do
  @moduledoc false
  alias Drab.Live.HTML

  defstruct tokenized: []

  @type token ::
          {:tag, String.t()} | {:text, String.t()} | {:naked, String.t()} | {:comment, String.t()}

  @type t :: %HTML{
          tokenized: list
        }

  @doc """
  Simple html tokenizer. Works with nested lists.

      iex> tokenize("<html> <body >some<b> anything</b></body ></html>")
      %Drab.Live.HTML{tokenized: [{:tag, "html"}, {:text, " "}, {:tag, "body "}, {:text, "some"},
      {:tag, "b"}, {:text, " anything"},
      {:tag, "/b"}, {:tag, "/body "}, {:tag, "/html"}, {:text, ""}]}

      iex> tokenize("some")
      %Drab.Live.HTML{tokenized: [{:text, "some"}]}

      iex> tokenize(["some"])
      [%Drab.Live.HTML{tokenized: [{:text, "some"}]}]

      iex> tokenize("")
      %Drab.Live.HTML{tokenized: [{:text, ""}]}

      iex> tokenize([""])
      [%Drab.Live.HTML{tokenized: [{:text, ""}]}]

      iex> tokenize("<!-- comment -->")
      %Drab.Live.HTML{tokenized: [comment: "-- comment --", text: ""]}

      iex> tokenize("<!--comment--> text")
      %Drab.Live.HTML{tokenized: [comment: "--comment--", text: " text"]}

      iex> tokenize("<tag> and more")
      %Drab.Live.HTML{tokenized: [{:tag, "tag"}, {:text, " and more"}]}

      iex> tokenize("<tag> <naked tag")
      %Drab.Live.HTML{tokenized: [{:tag, "tag"}, {:text, " "}, {:naked, "naked tag"}]}

      iex> tokenize(["<tag a/> <naked tag"])
      [%Drab.Live.HTML{tokenized: [{:tag, "tag a/"}, {:text, " "}, {:naked, "naked tag"}]}]

      iex> tokenize(["other", "<tag a> <naked tag"])
      [%Drab.Live.HTML{tokenized: [{:text, "other"}]},
      %Drab.Live.HTML{tokenized: [{:tag, "tag a"}, {:text, " "}, {:naked, "naked tag"}]}]

      iex> tokenize(["other", :atom, "<tag a/> <naked tag"])
      [%Drab.Live.HTML{tokenized: [{:text, "other"}]}, :atom,
      %Drab.Live.HTML{tokenized: [{:tag, "tag a/"}, {:text, " "}, {:naked, "naked tag"}]}]

      iex> tokenize(["<tag", :atom, ">"])
      [%Drab.Live.HTML{tokenized: [naked: "tag"]},
      :atom, %Drab.Live.HTML{tokenized: [{:text, ">"}]}]

      iex> tokenize [do: {:->, [line: 3], [["set in the commander"], "commander"]}]
      [
        do: {:->, [line: 3],
        [
          [%Drab.Live.HTML{tokenized: [text: "set in the commander"]}],
          %Drab.Live.HTML{tokenized: [text: "commander"]}
        ]}
      ]

      iex> tokenize("<!-- Comment -->")
      %Drab.Live.HTML{tokenized: [comment: "-- Comment --", text: ""]}

      iex> tokenize("<!DOCTYPE html>")
      %Drab.Live.HTML{tokenized: [comment: "DOCTYPE html", text: ""]}
  """
  def tokenize(string) when is_binary(string) do
    %HTML{tokenized: tokenize_string(string)}
  end

  def tokenize({code, meta, args}) do
    {code, meta, tokenize(args)}
  end

  @block ~w(do end catch rescue after else)a
  def tokenize({atom, args}) when atom in @block do
    {atom, tokenize(args)}
  end

  def tokenize([head | tail]) do
    [tokenize(head) | tokenize(tail)]
  end

  def tokenize(other) do
    other
  end

  @spec tokenize_string(String.t()) :: list
  defp tokenize_string("<" <> rest) do
    case String.split(rest, ">", parts: 2) do
      # naked tag can be only at the end
      [tag] ->
        [{:naked, trim_and_lower(tag)}]

      ["!" <> comment | tail] ->
        [{:comment, comment} | tokenize_string(Enum.join(tail))]

      [tag | tail] ->
        [{:tag, trim_and_lower(tag)} | tokenize_string(Enum.join(tail))]
    end
  end

  defp tokenize_string(string) when is_binary(string) do
    case String.split(string, "<", parts: 2) do
      [no_more_tags] -> [{:text, no_more_tags}]
      [text, rest] -> [{:text, text} | tokenize_string("<" <> rest)]
    end
  end

  defp trim_and_lower(string) do
    string |> String.trim_leading() |> lowercase_tag_name()
  end

  defp lowercase_tag_name(string) do
    tag = tag_name(string)
    String.replace(string, ~r/^\/?#{tag}/, String.downcase(tag))
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

      iex> html = ["other", [:atom, "<tag a> </tag>", {:other}]]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ["<tag", :atom, ">"]
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "<!-- Comment -->"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "<!DOCTYPE html>"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true
  """
  def tokenized_to_html([]), do: []
  def tokenized_to_html(%HTML{tokenized: tokenized}), do: Enum.join(htmlize(tokenized))
  def tokenized_to_html({code, meta, args}), do: {code, meta, tokenized_to_html(args)}
  def tokenized_to_html({atom, args}) when atom in @block, do: {atom, tokenized_to_html(args)}
  def tokenized_to_html([head | tail]), do: [tokenized_to_html(head) | tokenized_to_html(tail)]
  def tokenized_to_html(other), do: other

  defp htmlize([]), do: []
  defp htmlize([head | tail]), do: [htmlize(head) | htmlize(tail)]
  defp htmlize({:tag, tag}), do: "<#{tag}>"
  defp htmlize({:naked, tag}), do: "<#{tag}"
  defp htmlize({:text, text}), do: text
  defp htmlize({:comment, comment}), do: "<!#{comment}>"

  @doc """
  Injects given attribute to the last found opened (or naked) tag.

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
  """
  @spec inject_attribute_to_last_opened(String.t() | list | Macro.t(), String.t()) ::
          {:ok | :not_found | :already_there, String.t() | list | Macro.t(), String.t()}
  def inject_attribute_to_last_opened(buffer, attribute) when is_tuple(buffer) do
    # in case when there is no text between expressions
    {result, [acc], attribute} = inject_attribute_to_last_opened([buffer], attribute)
    {result, acc, attribute}
  end

  def inject_attribute_to_last_opened(buffer, attribute) do
    {_, found, acc} =
      buffer
      |> tokenize()
      |> deep_reverse()
      |> do_inject(attribute, [], :not_found, [])

    acc = acc |> deep_reverse() |> tokenized_to_html()

    case found do
      :not_found -> {:not_found, acc, attribute}
      other when other == attribute -> {:ok, acc, attribute}
      _ -> {:already_there, acc, found}
    end
  end

  @non_closing_tags ~w{
    area base br col command embed hr img input keygen link meta param source track wbr
    area/ base/ br/ col/ command/ embed/ hr/ img/ input/ keygen/ link/ meta/ param/ source/ track/
    wbr/
  }

  defp do_inject([], _, opened, found, acc) do
    {opened, found, acc}
  end

  defp do_inject([head | tail], attribute, closed, found, acc) do
    case head do
      %HTML{} = tokenized_html ->
        {cls, fnd, tkn} = inject_to_html(tokenized_html, attribute, closed, found)
        do_inject(tail, attribute, cls, fnd, acc ++ [tkn])

      {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | buffer]} | rest]} ->
        {op, fd, ac} = do_inject(buffer, attribute, closed, found, [])

        modified_buffer =
          {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | ac]} | rest]}

        do_inject(tail, attribute, op, fd, acc ++ [modified_buffer])

      list when is_list(list) ->
        {op, fd, modified_buffer} = do_inject(list, attribute, closed, found, [])
        do_inject(tail, attribute, op, fd, acc ++ [modified_buffer])

      _ ->
        do_inject(tail, attribute, closed, found, acc ++ [head])
    end
  end

  @doc """
  Injects attribute to the last opened tag in tokenized html.

      iex> {_closed, "attr=1", tokenized} = inject_to_html tokenize("<tag>"), "attr=1"
      iex> tokenized_to_html(tokenized)
      "<tag attr=1>"

      iex> {_closed, "attr=1", tokenized} = inject_to_html tokenize("<tag attr2>"), "attr=1"
      iex> tokenized_to_html(tokenized)
      "<tag attr=1 attr2>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<TAG attr2><tag></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag attr=1 attr2><tag></tag>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag></TAG><tag attr2"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag></tag><tag attr=1 attr2"

      iex> {_closed, "attr=2", tked} = inject_to_html tokenize("<img attr=2 src"), "attr=1"
      iex> tokenized_to_html(tked)
      "<img attr=2 src"

      iex> {_closed, "attr=2", tked} = inject_to_html tokenize("<Img attr=2 src>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<img attr=2 src>"

      iex> {_closed, "attr=2", tokenized} = inject_to_html tokenize("<tag attr=2>"), "attr=1"
      iex> tokenized_to_html(tokenized)
      "<tag attr=2>"

      iex> {_closed, "attr=2", tokenized} = inject_to_html tokenize("<tag attr=2 attr2>"), "attr=1"
      iex> tokenized_to_html(tokenized)
      "<tag attr=2 attr2>"

      iex> {_closed, "attr=2", tked} = inject_to_html tokenize("<tag attr=2><tag></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag attr=2><tag></tag>"

      iex> {_closed, "attr=2", tked} = inject_to_html tokenize("<tag></tag><tag attr2 attr=2"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag></tag><tag attr2 attr=2"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag><tag attr2"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag><tag attr=1 attr2"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag><tag attr2>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag><tag attr=1 attr2>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tAg><hr/><taG Attr2></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag attr=1><hr/><tag Attr2></tag>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag><br><tag attr2></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag attr=1><br><tag attr2></tag>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag><tag></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag attr=1><tag></tag>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<img src"), "attr=1"
      iex> tokenized_to_html(tked)
      "<img attr=1 src"

      iex> {_closed, :not_found, tked} = inject_to_html tokenize("<hr>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<hr>"

      iex> {_closed, "attr=1", tked} = inject_to_html tokenize("<tag 1><tag 2><tag 3></tag>"), "attr=1"
      iex> tokenized_to_html(tked)
      "<tag 1><tag attr=1 2><tag 3></tag>"

      iex> {_closed, "attr='3'", tked} = inject_to_html tokenize("<tag 1><tag 2><tag 3></tag></tag>"), "attr='3'"
      iex> tokenized_to_html(tked)
      "<tag attr='3' 1><tag 2><tag 3></tag></tag>"

      iex> {_closed, :not_found, tked} = inject_to_html tokenize("<Tag 1></tag>"), "attr=x"
      iex> tokenized_to_html(tked)
      "<tag 1></tag>"

      iex> {_closed, :not_found, tked} = inject_to_html tokenize("Text only"), "attr=x"
      iex> tokenized_to_html(tked)
      "Text only"

      iex> {_closed, :not_found, tked} = inject_to_html tokenize("<tag 1><tag 2><tag 3></tag></tag></tag>"), "attr=x"
      iex> tokenized_to_html(tked)
      "<tag 1><tag 2><tag 3></tag></tag></tag>"
  """
  @spec inject_to_html(HTML.t(), String.t(), list, String.t() | atom) ::
          {list, String.t() | atom, HTML.t()}
  def inject_to_html(%HTML{tokenized: tokenized_html}, attr, closed \\ [], found \\ :not_found) do
    tokens = Enum.reverse(tokenized_html)

    {closed, found, acc} =
      Enum.reduce(tokens, {closed, found, []}, fn
        # move on, if already found
        token, {closed, found, acc} when is_binary(found) ->
          {closed, found, [token | acc]}

        # if there is a naked tag, inject there
        {:naked, _tag} = token, {closed, :not_found, acc} ->
          inject_attribute(token, closed, attr, acc)

        # move on if this is non closing tag
        {:tag, tag} = token, {closed, :not_found, acc} when tag in @non_closing_tags ->
          {closed, :not_found, [token | acc]}

        # closing tag, add it to the closed tags list
        {:tag, "/" <> tag} = token, {closed, :not_found, acc} ->
          {[tag_name(tag) | closed], :not_found, [token | acc]}

        # the list of closed tags in empty, we may inject here
        {:tag, _tag} = token, {[], :not_found, acc} ->
          inject_attribute(token, [], attr, acc)

        # there are closed tag
        {:tag, tag} = token, {closed, :not_found, acc} ->
          if tag_name(tag) in closed do
            # was closed before, ignoring
            {closed -- [tag_name(tag)], :not_found, [token | acc]}
          else
            inject_attribute(token, closed, attr, acc)
          end

        token, {closed, found, acc} ->
          {closed, found, [token | acc]}
      end)

    {closed, found, %HTML{tokenized: acc}}
  end

  defp inject_attribute({gender, tag} = token, closed, attribute, acc) do
    case find_attribute(tag, attribute) do
      # attribute not found, do inject and return injected
      nil ->
        {closed, attribute, [{gender, add_attribute(tag, attribute)} | acc]}

      # attribute is already there; do not inject but return existing
      found_attr ->
        {closed, found_attr, [token | acc]}
    end
  end

  defp tag_name(tag) do
    tag |> String.split(~r/\s/) |> List.first()
  end

  @doc """
  Gets the attribute hash from "drab-ampere="ampere_hash" string.

      iex> extract_ampere_hash(~s/drab-ampere="giydcmrsgy4tsnbx"/)
      "giydcmrsgy4tsnbx"
      iex> extract_ampere_hash("anything else")
      nil
  """
  def extract_ampere_hash(attribute) do
    captures = Regex.named_captures(~r/drab-ampere="(?<ampere>\S+)"/, attribute)
    captures["ampere"]
  end

  @doc """
  Add attribute to a tag.

      iex> add_attribute("tag tag=2", "attr=1")
      "tag attr=1 tag=2"
  """
  @spec add_attribute(String.t(), String.t()) :: String.t()
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
  @spec find_attribute(String.t(), String.t()) :: String.t() | nil
  def find_attribute(tag, attr) do
    [attr_name | _] =
      attr
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
  @spec to_flat_html(Phoenix.HTML.safe() | list) :: String.t()
  def to_flat_html({:safe, body}), do: to_flat_html(body)
  def to_flat_html(body), do: body |> do_to_flat_html() |> List.flatten() |> Enum.join()

  defp do_to_flat_html([]), do: []
  defp do_to_flat_html(body) when is_binary(body), do: [body]
  # tmp1 is in generating output expression <%= %>
  defp do_to_flat_html(
         {:__block__, [], [{:=, [], [{:tmp1, [], Drab.Live.EExEngine} | buffer]} | rest]}
       ) do
    do_to_flat_html(buffer) ++ do_to_flat_html(rest)
  end

  # while tmp2 inidcates the expression inside <% %>
  defp do_to_flat_html(
         {:__block__, [], [{:=, [], [{:tmp2, [], Drab.Live.EExEngine} | buffer]} | _]}
       ) do
    do_to_flat_html(buffer)
  end

  defp do_to_flat_html([head | rest]), do: do_to_flat_html(head) ++ do_to_flat_html(rest)
  defp do_to_flat_html({_, _, list}) when is_list(list), do: do_to_flat_html(list)
  defp do_to_flat_html({_, _, _}), do: []
  defp do_to_flat_html(atom) when is_atom(atom), do: []
  defp do_to_flat_html({_, buffer}), do: do_to_flat_html(buffer)
  # TODO: rething, may be insecure
  defp do_to_flat_html(_), do: []

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
      iex> in_opened_tag? "<!--comment-->"
      false
      iex> in_opened_tag? "<!--comment"
      false
  """
  @spec in_opened_tag?(Phoenix.HTML.safe() | list) :: boolean
  def in_opened_tag?({:safe, body}), do: in_opened_tag?(body)

  def in_opened_tag?(body) do
    case last_tag(tokenized(body)) do
      {_, tag} -> not (String.starts_with?(tag, "/") or String.starts_with?(tag, "!"))
      nil -> false
    end
  end

  @doc """
  True if the expression is inside <!-- comment --> or <!doctype> tag

      iex> in_comment_or_doctype? "<!--comment"
      true
      iex> in_comment_or_doctype? "<!--comment-->"
      false
      iex> in_comment_or_doctype? "<!--comment--><a>"
      false
      iex> in_comment_or_doctype? "<!--comment--><a></a>"
      false
  """
  @spec in_comment_or_doctype?(Phoenix.HTML.safe() | list) :: boolean
  def in_comment_or_doctype?({:safe, body}), do: in_comment_or_doctype?(body)

  def in_comment_or_doctype?(body) do
    case last_tag(tokenized(body)) do
      {:naked, "!" <> _} -> true
      _ -> false
    end
  end

  defp tokenized(body) do
    body
    |> to_flat_html()
    |> tokenize()
  end

  defp last_tag(%HTML{tokenized: tokenized}) do
    tokenized
    |> Enum.filter(fn
      {:naked, _} -> true
      {:tag, x} -> tag_name(x) not in @non_closing_tags
      _ -> false
    end)
    |> Enum.reverse()
    |> Enum.find(&match?({_, _}, &1))
  end

  @doc """
  Returns amperes and patterns from flat html.
  Pattern is processed by Floki, so it doesn't have to be the same as original!
  """
  @spec amperes_from_buffer(Phoenix.HTML.safe() | list) :: map
  def amperes_from_buffer({:safe, buffer}) when is_list(buffer) do
    buffer
    |> to_flat_html()
    |> amperes_from_html()
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
      [{key, value}] when is_atom(key) ->
        Map.merge(amperes_from_buffer(tail), amperes_from_buffer(value))

      _ ->
        amperes_from_buffer(tail)
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

  # defp amperes_from_html(list) when is_list(list), do: amperes_from_html(to_flat_html(list))
  @spec amperes_from_html(String.t()) :: map
  defp amperes_from_html(html) when is_binary(html) do
    with_amperes =
      html
      |> Floki.parse()
      |> Floki.find("[drab-ampere]")

    for {tag, attributes, inner_html} <- with_amperes, into: Map.new() do
      ampere = find_ampere(attributes)

      html_part =
        if contains_expression?(inner_html),
          do: [{:html, tag, "innerHTML", Floki.raw_html(inner_html, encode: false)}],
          else: []

      attrs_part =
        for {attr_name, attr_pattern} <- attributes, contains_expression?(attr_pattern) do
          case attr_name do
            "@" <> prop_name ->
              {:prop, tag, case_sensitive_prop_name(html, ampere, prop_name), attr_pattern}

            _ ->
              {:attr, tag, attr_name, attr_pattern}
          end
        end

      {ampere, html_part ++ attrs_part}
    end
  end

  @doc """
  Finds a real property name (case sensitive), based on the attribute (lowercased) name
  """
  @spec case_sensitive_prop_name(String.t(), String.t(), String.t()) :: String.t()
  def case_sensitive_prop_name(html, ampere, prop_name) do
    %HTML{tokenized: tokenized} = tokenize(html)

    {:tag, body} =
      Enum.find(tokenized, fn x ->
        case x do
          {:tag, tag} -> String.contains?(tag, "drab-ampere=\"#{ampere}\"")
          _ -> false
        end
      end)

    [_, property] = Regex.run(~r/@(#{prop_name})\s*=/i, body)
    property
  end

  defp find_ampere(attributes) do
    {_, ampere} = Enum.find(attributes, fn {name, _} -> name == "drab-ampere" end)
    ampere
  end

  @expr_begin ~r/{{{{@drab-expr-hash:(\S+)}}}}/
  @expr_end ~r/{{{{\/@drab-expr-hash:\S+}}}}/
  @partial ~r/{{{{@drab-partial:\S+}}}}/
  defp contains_expression?(html) when is_binary(html) do
    Regex.match?(@expr_begin, html)
  end

  defp contains_expression?(html) do
    html |> Floki.raw_html(encode: false) |> contains_expression?()
  end

  @doc """
  Removes all Drab's marks from the buffer
  """
  @spec remove_drab_marks(Phoenix.HTML.safe() | list) :: Phoenix.HTML.safe() | list
  def remove_drab_marks({:safe, buffer}) do
    {:safe, remove_drab_marks(buffer)}
  end

  def remove_drab_marks(buffer) do
    Macro.prewalk(buffer, fn
      text when is_binary(text) ->
        text
        |> String.replace(@expr_begin, "", global: true)
        |> String.replace(@expr_end, "", global: true)
        |> String.replace(@partial, "", global: true)

      x ->
        x
    end)
  end

  @doc """
  Find drab marks inside the given expression, used to determine children expressions
  """
  @spec find_expr_hashes(Macro.t()) :: [String.t()]
  def find_expr_hashes(buffer) do
    {_, acc} =
      Macro.prewalk(buffer, [], fn
        text, acc when is_binary(text) ->
          if Regex.match?(@expr_begin, text) do
            {text, [text | acc]}
          else
            {text, acc}
          end

        x, acc ->
          {x, acc}
      end)

    acc
    |> Enum.map(&Regex.run(@expr_begin, &1, capture: :all_but_first))
    |> List.flatten()
  end

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
  @spec deep_reverse(list) :: list
  def deep_reverse(list) do
    list
    |> Enum.reverse()
    |> Enum.map(fn
      {:__block__, [], [{:=, [], [{tmp, [], Drab.Live.EExEngine} | buffer]} | rest]} ->
        {:__block__, [],
         [{:=, [], [{tmp, [], Drab.Live.EExEngine} | deep_reverse(buffer)]} | deep_reverse(rest)]}

      x when is_list(x) ->
        deep_reverse(x)

      x ->
        x
    end)
  end
end
