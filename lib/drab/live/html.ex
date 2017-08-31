defmodule Drab.Live.HTML do
  @moduledoc false

  @doc """
  Simple html tokenizer. Works with nested lists.

      iex> tokenize("<html> <body >some<b> anything</b></body ></html>")
      [{:tag, "html"}, " ", {:tag, "body "}, "some", {:tag, "b"}, " anything",
      {:tag, "/b"}, {:tag, "/body "}, {:tag, "/html"}]

      iex> tokenize("some")
      ["some"]

      iex> tokenize("<tag> and more")
      [{:tag, "tag"}, " and more"]

      iex> tokenize("<tag> <naked tag")
      [{:tag, "tag"}, " ", {:naked, "naked tag"}]

      iex> tokenize(["<tag a> <naked tag"])
      [[{:tag, "tag a"}, " ", {:naked, "naked tag"}]]

      iex> tokenize(["other", "<tag a> <naked tag"])
      [["other"], [{:tag, "tag a"}, " ", {:naked, "naked tag"}]]
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

  @doc """
  Detokenizer. Leading spaces in the tag are removed! (< html> becomes <html>).

      iex> html = "<html> <body >some<b> anything</b></body ></html>"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = "text"
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ""
      iex> html |> tokenize() |> tokenized_to_html() == html
      true

      iex> html = ""
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
  """
  def tokenized_to_html([]), do: ""
  def tokenized_to_html([head]) when is_list(head), do: [tokenized_to_html(head)]
  def tokenized_to_html([head | tail]) when is_list(head), do: [tokenized_to_html(head) | tokenized_to_html(tail)]
  def tokenized_to_html([head | tail]), do: tokenized_to_html(head) <> tokenized_to_html(tail)
  def tokenized_to_html({:tag, tag}), do: "<#{tag}>"
  def tokenized_to_html({:naked, tag}), do: "<#{tag}"
  def tokenized_to_html(text), do: text

  # @doc """
  # Returns the name of the last opened tag.

  #     iex> last_opened_tag("<html><b> </b>")
  #     "html"

  #     iex> last_opened_tag(" <html> </b><b>")
  #     "b"

  #     iex> last_opened_tag(" <html> </b><b></c>")
  #     nil

  #     iex> last_opened_tag("<html><b></b> <tag x")
  #     "tag"

  #     iex> last_opened_tag("<a><b><c>")
  #     "c"

  #     iex> last_opened_tag("<a><b></b><c>")
  #     "c"

  #     iex> last_opened_tag("<a><b></b><c></c>")
  #     "a"

  #     iex> last_opened_tag("<x><a><b></b><c></c></x>")
  #     nil

  #     iex> last_opened_tag("<a><b></b><x><c></c></x>")
  #     "a"

  #     iex> last_opened_tag("<tag>")
  #     "tag"

  #     iex> last_opened_tag("<tag></tag>")
  #     nil

  #     iex> last_opened_tag("</tag>")
  #     nil

  #     iex> last_opened_tag("text")
  #     nil

  #     iex> last_opened_tag("<a><b></b></a>")
  #     nil
  # """
  # def last_opened_tag(html) do
  #   tags = tokenize(html) |> Enum.reverse()
  #   do_last_opened_tag(tags)
  # end

  # defp do_last_opened_tag([]) do
  #   nil
  # end
  # defp do_last_opened_tag([head | tail]) do
  #   case head do
  #     "/" <> tag ->
  #       case Enum.split_while(tail, &(&1 != tag)) do
  #         {_, [_ | rest]} -> do_last_opened_tag(rest)
  #         _ -> nil
  #       end
  #     tag -> tag
  #   end
  # end

  @non_closing_tags ~w{area base br col embed hr img input keygen link meta param source track wbr}
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
  """
  def inject_attribute_to_last_opened(html, attribute) when is_binary(html) do
    tokenized = tokenize(html) |> Enum.reverse()
    injected = do_inject(tokenized, attribute, []) |> List.flatten() |> Enum.reverse() |> tokenized_to_html()
    ret = if injected == html, do: :not_found, else: :ok
    {ret, injected}
  end

  defp do_inject([], _, _) do
    []
  end
  defp do_inject([head | tail] = tokenized, attribute, opened) do
    case head do
      {:naked, tag} -> # naked can be only at the end
        [{:naked, add_attribute(tag, attribute)} | tail]
      {:tag, "/" <> tag} ->
        [head, do_inject(tail, attribute, [tag_name(tag) | opened])]
      {:tag, tag} ->
        if Enum.find(opened, fn x -> tag_name(tag) == x end) do
          [head, do_inject(tail, attribute, opened -- [tag_name(tag)])]
        else
          [{:tag, add_attribute(tag, attribute)}] ++ tail
        end
      other -> [head | do_inject(tail, attribute, opened)]
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
end
