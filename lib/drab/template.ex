defmodule Drab.Template do
  require IEx
  require Logger

  @drab_templates "/templates/drab"

  @moduledoc false

  # compiling internal templates only
  # TODO: compile also user additional templates
  Logger.info("Compiling Drab Templates")

  drab_templates =
    [:drab |> :code.priv_dir() |> to_string(), @drab_templates, "*"]
    |> Path.join()
    |> Path.wildcard()

  for template_with_path <- drab_templates do
    @external_resource template_with_path

    filename = Path.basename(template_with_path)
    compiled = template_with_path |> EEx.compile_file() |> Macro.escape()

    defp compiled_template(unquote(filename)) do
      unquote(compiled)
    end
  end

  # catch-all is to give an error when file not found
  @spec compiled_template(String.t()) :: Macro.t() | no_return
  defp compiled_template(filename) do
    raise "Can't find the template `#{filename}` in priv."
  end

  @doc false
  @spec render_template(atom, String.t(), Keyword.t()) :: String.t()
  def render_template(endpoint, filename, bindings) do
    # TODO: this is not very efficient, as it searches for a template every single time
    p = Path.join(user_templates(endpoint), filename)

    if p |> File.exists?() do
      EEx.eval_file(p, bindings)
    else
      {result, _} = Code.eval_quoted(compiled_template(filename), bindings)
      result
    end
  end

  defp user_templates(endpoint) do
    case Drab.Config.get(endpoint, :templates_path) do
      "priv" <> rest ->
        priv = Drab.Config.app_name() |> :code.priv_dir() |> to_string()
        Path.join(priv, rest)

      path ->
        raise ":templates_path must start with `priv/`, given: #{path}"
    end
  end
end
