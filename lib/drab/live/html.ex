defmodule Drab.Live.HTML do
  @moduledoc false

  @doc """
  Simple html tokenizer. Works with nested lists.

      iex> tokenize("<html> <body >some<b> anything</b></body ></html>")
      [{:tag, "html"}, " ", {:tag, "body "}, "some", {:tag, "b"}, " anything",
      {:tag, "/b"}, {:tag, "/body "}, {:tag, "/html"}]

      iex> tokenize("some")
      ["some"]

      iex> tokenize(["some"])
      [["some"]]

      iex> tokenize("")
      []

      iex> tokenize([""])
      [[]]

      iex> tokenize("<tag> and more")
      [{:tag, "tag"}, " and more"]

      iex> tokenize("<tag> <naked tag")
      [{:tag, "tag"}, " ", {:naked, "naked tag"}]

      iex> tokenize(["<tag a> <naked tag"])
      [[{:tag, "tag a"}, " ", {:naked, "naked tag"}]]

      iex> tokenize(["other", "<tag a> <naked tag"])
      [["other"], [{:tag, "tag a"}, " ", {:naked, "naked tag"}]]

      iex> tokenize(["other", :atom, "<tag a> <naked tag"])
      [["other"], :atom, [{:tag, "tag a"}, " ", {:naked, "naked tag"}]]
  """
  def tokenize("") do
    []
  end
  def tokenize("<" <> rest) do
    case String.split(rest, ">", parts: 2) do
      [tag] -> [{:naked, String.trim_leading(tag)}] # naked tag can be only at the end
      # ["/" <> tag, tail] -> [{:tag, t/ag} | tokenize(Enum.join(tail))]
      [tag | tail] -> [{:tag, String.trim_leading(tag)} | tokenize(Enum.join(tail))]
    end
  end
  def tokenize(string) when is_binary(string) do
    case String.split(string, "<", parts: 2) do
      [no_more_tags] -> [no_more_tags]
      [text, rest] -> [text | tokenize("<" <> rest)]
    end
  end
  def tokenize([]) do
    []
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
      ""

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
  """
  def tokenized_to_html([]), do: ""

  def tokenized_to_html({:tag, tag}), do: "<#{tag}>"
  def tokenized_to_html({:naked, tag}), do: "<#{tag}"
  def tokenized_to_html(text) when not is_list(text), do: text
  # def tokenized_to_html([text]) when not is_list(text), do: text

  def tokenized_to_html([list]) when is_list(list), do: [tokenized_to_html(list)]
  def tokenized_to_html([head | tail]) when is_list(head), do: [tokenized_to_html(head) | tokenized_to_html(tail)]
  def tokenized_to_html([head | tail]), do: tokenized_to_html(head) <> tokenized_to_html(tail)

  @doc """
  Injects given attribute to the last found opened (or naked) tag.

    iex> inject_attribute_to_last_opened "<tag>", "attr=1"
    {:ok, "<tag attr=1>"}

    iex> inject_attribute_to_last_opened "<tag attr2>", "attr=1"
    {:ok, "<tag attr=1 attr2>"}

    iex> inject_attribute_to_last_opened "<tag attr2><tag></tag>", "attr=1"
    {:ok, "<tag attr=1 attr2><tag></tag>"}

    iex> inject_attribute_to_last_opened "<tag></tag><tag attr2", "attr=1"
    {:ok, "<tag></tag><tag attr=1 attr2"}

    iex> inject_attribute_to_last_opened "<tag><tag attr2", "attr=1"
    {:ok, "<tag><tag attr=1 attr2"}

    iex> inject_attribute_to_last_opened "<tag><tag attr2>", "attr=1"
    {:ok, "<tag><tag attr=1 attr2>"}

    iex> inject_attribute_to_last_opened "<tag><tag attr2></tag>", "attr=1"
    {:ok, "<tag attr=1><tag attr2></tag>"}

    iex> inject_attribute_to_last_opened "<tag><br><tag attr2></tag>", "attr=1"
    {:ok, "<tag attr=1><br><tag attr2></tag>"}

    iex> inject_attribute_to_last_opened "<img src", "attr=1"
    {:ok, "<img attr=1 src"}

    iex> inject_attribute_to_last_opened "<hr>", "attr=1"
    {:not_found, "<hr>"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag>", "attr"
    {:ok, "<tag 1><tag attr 2><tag 3></tag>"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag></tag>", "attr"
    {:ok, "<tag attr 1><tag 2><tag 3></tag></tag>"}

    iex> inject_attribute_to_last_opened "<tag 1></tag>", "attr"
    {:not_found, "<tag 1></tag>"}

    iex> inject_attribute_to_last_opened "text only", "attr"
    {:not_found, "text only"}

    iex> inject_attribute_to_last_opened "<tag 1><tag 2><tag 3></tag></tag></tag>", "attr"
    {:not_found, "<tag 1><tag 2><tag 3></tag></tag></tag>"}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2><tag 3></tag>", "</tag>"], "attr"
    {:ok, ["<tag attr 1><tag 2><tag 3></tag>", "</tag>"]}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", "<tag 3></tag>", "</tag>"], "attr"
    {:ok, ["<tag attr 1><tag 2>", "<tag 3></tag>", "</tag>"]}

    iex> inject_attribute_to_last_opened ["<tag 1><tag 2>", ["<tag 3>", "</tag>"]], "attr"
    {:ok, ["<tag 1><tag attr 2>", ["<tag 3>", "</tag>"]]}
  """
  def inject_attribute_to_last_opened(html, attribute) do
    {_, found, acc} = html
      |> tokenize()
      |> deep_reverse()
      |> do_inject(attribute, [], false, [])
    acc = tokenized_to_html(acc)
    if found, do: {:ok, acc}, else: {:not_found, acc}
  end

  @non_closing_tags ~w{area base br col embed hr img input keygen link meta param source track wbr}
  defp do_inject([], _, opened, found, acc) do
    {opened, found, acc}
  end
  defp do_inject([head | tail], attribute, opened, found, acc) do
    case head do
      {:naked, tag} -> # naked can be only at the end
        do_inject(tail, attribute, opened, true, [{:naked, add_attribute(tag, attribute)} | acc])
      {:tag, "/" <> tag} ->
        do_inject(tail, attribute, [tag_name(tag) | opened], found, [head | acc])
      {:tag, tag} ->
        if Enum.find(opened, fn x -> tag_name(tag) == x end) do
          do_inject(tail, attribute, opened -- [tag_name(tag)], found, [head | acc])
        else
          if found || Enum.member?(@non_closing_tags, tag_name(tag)) do
            do_inject(tail, attribute, opened, found, [head | acc])
          else
            do_inject(tail, attribute, opened, true, [{:tag, add_attribute(tag, attribute)} | acc])
          end
        end
      list when is_list(list) ->
        {op, fd, ac} = do_inject(list, attribute, opened, found, [])
        do_inject(tail, attribute, op, fd, [ac | acc])
      _ ->
        do_inject(tail, attribute, opened, found, [head | acc])
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
      x when is_list(x) -> deep_reverse(x)
      x -> x
    end)
  end
end
