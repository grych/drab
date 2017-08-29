defmodule Drab.Live.HTML do
  @moduledoc false

  @doc """
  Simple html tokenizer, extracts tags only.

      iex> tokenize("<html> <body >some<b> anything</b></body ></html>")
      ["html", "body", "b", "/b", "/body", "/html"]

      iex> tokenize("some")
      []

      iex> tokenize("<tag>")
      ["tag"]

      iex> tokenize("<tag> <naked tag")
      ["tag", "naked"]
  """
  def tokenize("") do
    []
  end
  def tokenize("<" <> rest) do
    [tag | tail] = String.split(rest, ~r/[\s>]/, parts: 2)
    [tag | tokenize(Enum.join(tail))]
  end
  def tokenize(<<_ :: utf8>> <> rest) do
    tokenize(rest)
  end

  @doc """
  Returns the name of the last opened tag.

      iex> last_opened_tag("<html><b> </b>")
      "html"

      iex> last_opened_tag(" <html> </b><b>")
      "b"

      iex> last_opened_tag(" <html> </b><b></c>")
      nil

      iex> last_opened_tag("<html><b></b> <tag x")
      "tag"

      iex> last_opened_tag("<a><b><c>")
      "c"

      iex> last_opened_tag("<a><b></b><c>")
      "c"

      iex> last_opened_tag("<a><b></b><c></c>")
      "a"

      iex> last_opened_tag("<x><a><b></b><c></c></x>")
      nil

      iex> last_opened_tag("<a><b></b><x><c></c></x>")
      "a"

      iex> last_opened_tag("<tag>")
      "tag"

      iex> last_opened_tag("<tag></tag>")
      nil

      iex> last_opened_tag("</tag>")
      nil

      iex> last_opened_tag("text")
      nil

      iex> last_opened_tag("<a><b></b></a>")
      nil
  """
  def last_opened_tag(html) do
    tags = tokenize(html) |> Enum.reverse()
    do_last_opened_tag(tags)
  end

  defp do_last_opened_tag([]) do
    nil
  end
  defp do_last_opened_tag([head | tail]) do
    case head do
      "/" <> tag ->
        case Enum.split_while(tail, &(&1 != tag)) do
          {_, [_ | rest]} -> do_last_opened_tag(rest)
          _ -> nil
        end
      tag -> tag
    end
  end
  # defp do_last_opened_tag(["/" <> tag | rest]) do
  #   IO.puts("tag: #{tag}")
  #   {_, rest} = Enum.split_while(rest, &(&1 != tag))
  #   do_last_opened_tag(rest)
  # end
  # defp do_last_opened_tag([tag | []]) do
  #   tag
  # end
  # defp do_last_opened_tag([_ | rest]) do
  #   do_last_opened_tag(rest)
  # end
end
