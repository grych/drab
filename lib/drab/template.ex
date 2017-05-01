defmodule Drab.Template do
  require IEx
  require Logger

  @drab_templates "priv/templates/drab"

  @moduledoc false

  # compiling internal templates only
  # TODO: find a way to compile also user additional templates
  Logger.info "Compiling Drab Templates"

  drab_templates = Path.join(@drab_templates, "*") |> Path.wildcard()
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

  # defp find_template(filename) do
  #   sources =  template_paths() |> Enum.map(&(Path.join(&1, filename)))
  #   Enum.find(sources, &(File.exists?(&1))) || 
  #     raise "Can't find the template `#{filename}` in `#{user_templates()}`"
  # end

  # defp template_dir(app) when is_atom(app) do
  #   Application.app_dir(app) |> Path.join(@drab_templates)
  # end
  # defp template_dir(path) when is_binary(path) do
  #   # Path.join(path, @drab_templates)
  #   Path.join(".", path)
  # end

  # defp paths(), do: [user_templates(), :drab]

  # defp template_paths(), do: Enum.map(paths(), &(template_dir(&1)))

  defp user_templates(), do: Drab.config.templates_path
end
