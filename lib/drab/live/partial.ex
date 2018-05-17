defmodule Drab.Live.Partial do
  @moduledoc false
  alias Drab.Live.{Ampere, Partial}

  @type t :: %Drab.Live.Partial{
          path: String.t(),
          hash: String.t(),
          amperes: %{String.t() => [Ampere.t()]},
          assigns: %{atom => [String.t()]}
        }
  defstruct path: "", hash: "", amperes: %{}, assigns: %{}

  @doc """
  Returns %Drab.Live.Partial{} for the given hash.

      iex> match? %Drab.Live.Partial{}, partial("gm2dgnjygm2dgnjt")
      true
      iex> partial("gm2dgnjygm2dgnjt").hash
      "gm2dgnjygm2dgnjt"
      iex> partial("gm2dgnjygm2dgnjt").path
      "test/support/web/templates/live/live_engine_test.html.drab"
  """
  @spec partial(String.t()) :: t
  def partial(hash) do
    module(hash).partial()
  end

  @doc """
  Returns module for the given hash. Raises when not found.

      iex> module("gm2dgnjygm2dgnjt")
      Drab.Live.Template.Gm2dgnjygm2dgnjt
  """
  @spec module(String.t()) :: atom | no_return
  def module(hash) do
    module = Drab.Live.Engine.module_name(hash)
    unless Code.ensure_loaded?(module), do: Drab.Live.raise_partial_not_found(hash)
    module
  end

  @doc """
  Returns the filename, without drab extension, for the template

      iex> template_filename(DrabTestApp.LiveView, "gm2dgnjygm2dgnjt")
      "live_engine_test.html"
      iex> template_filename(DrabTestApp.LiveView, "gm4diobvgmytknbt")
      "subfolder/subpartial.html"
  """
  @spec template_filename(atom, String.t()) :: String.t()
  def template_filename(view, hash) do
    template = Path.relative_to module(hash).path(), templates_path(view)
    Path.rootname(template, Drab.Config.drab_extension())
  end

  @doc """
  Returns partial hash for the given view and filename.

      iex> hash_for_view_and_name(DrabTestApp.LiveView, "live_engine_test.html")
      "gm2dgnjygm2dgnjt"
  """
  @spec hash_for_view_and_name(atom, String.t()) :: String.t() | no_return
  def hash_for_view_and_name(view, partial_name) do
    path = partial_path(view, partial_name)
    Drab.Live.Crypto.hash(path)
  end

  @spec partial_path(atom, String.t()) :: String.t()
  defp partial_path(view, partial_name) do
    Path.join(templates_path(view), partial_name <> Drab.Config.drab_extension())
  end

  @spec templates_path(atom) :: String.t()
  defp templates_path(view) do
    {path, _, _} = view.__templates__()
    path
  end

  @doc """
  Returns list of amperes for the given assign.

      iex> amperes_for_assign("gm2dgnjygm2dgnjt", :color)
      ["gi3dmojvga3tknbz", "gi4dcmbygq3tmnrt"]
      iex> amperes_for_assign("gm2dgnjygm2dgnjt", :text)
      ["gi2dcmbrgqztmobz", "gi3dmojvga3tknbz", "gi4dcmbygq3tmnrt"]
      iex> amperes_for_assign("gm2dgnjygm2dgnjt", :nonexistent)
      []
  """
  @spec amperes_for_assign(t | String.t(), atom) :: [String.t()]
  def amperes_for_assign(%Partial{} = partial, assign) do
    # this branch is calculating list of amperes
    # should be used in compile-time only
    Enum.uniq(
      for {ampere_id, amperes} <- partial.amperes,
          ampere <- amperes,
          assign in ampere.assigns do
        ampere_id
      end
    )
  end

  def amperes_for_assign(hash, assign) when is_binary(hash) do
    # this branch is to be used in the runtime
    Map.get(partial(hash).assigns, assign, [])
  end

  @doc """
  Returns list of amperes for the given assign list.

      iex> amperes_for_assigns("gm2dgnjygm2dgnjt", [:color])
      ["gi3dmojvga3tknbz", "gi4dcmbygq3tmnrt"]
      iex> amperes_for_assigns("gm2dgnjygm2dgnjt", [:text])
      ["gi2dcmbrgqztmobz", "gi3dmojvga3tknbz", "gi4dcmbygq3tmnrt"]
      iex> amperes_for_assigns("gm2dgnjygm2dgnjt", [:color, :text]) |> Enum.sort()
      ["gi2dcmbrgqztmobz", "gi3dmojvga3tknbz", "gi4dcmbygq3tmnrt"]
      iex> amperes_for_assigns("gm2dgnjygm2dgnjt", [:nonexistent])
      []
  """
  @spec amperes_for_assigns(String.t(), [atom]) :: [String.t()]
  def amperes_for_assigns(hash, assigns) do
    for assign <- assigns do
      amperes_for_assign(hash, assign)
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  @doc """
  Returns list of all assigns for a given partial hash or %Partial{}

      iex> all_assigns("gm2dgnjygm2dgnjt") |> Enum.sort()
      [:color, :text]
  """
  @spec all_assigns(t | String.t()) :: [atom]
  def all_assigns(%Partial{} = partial) do
    for {_ampere_id, amperes} <- partial.amperes,
        ampere <- amperes do
      ampere.assigns
    end
    |> List.flatten()
    |> Enum.uniq()
  end

  def all_assigns(hash) when is_binary(hash) do
    all_assigns(partial(hash))
  end
end
