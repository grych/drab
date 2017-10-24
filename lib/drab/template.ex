defmodule Drab.Template do
  require IEx
  require Logger

  @drab_templates "/templates/drab"

  @moduledoc false

  # compiling internal templates only
  # TODO: find a way to compile also user additional templates
  Logger.info "Compiling Drab Templates"

  drab_templates = Path.join([:code.priv_dir(:drab) |> to_string(), @drab_templates, "*"]) |> Path.wildcard()

  for template_with_path <- drab_templates do
    @external_resource template_with_path

    filename = Path.basename(template_with_path)
    compiled = EEx.compile_file(template_with_path) |> Macro.escape

    defp compiled_template(unquote(filename)) do
      unquote(compiled)
    end
  end

  # catch-all is to give a warning when file not found
  defp compiled_template(filename) do
    raise "Can't find the template `#{filename}` in `#{user_templates()}`"
  end

  @doc false
  def render_template(filename, bindings) do
    # TODO: this is not very efficient, as it searches for a template every single time
    p = Path.join(user_templates(), filename)
    if p |> File.exists? do
      EEx.eval_file(p, bindings)
    else
      {result, _} = Code.eval_quoted(compiled_template(filename), bindings)
      result
    end
  end

  defp user_templates(), do: Drab.Config.get(:templates_path)
end
