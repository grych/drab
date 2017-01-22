defmodule Drab.Template do
  require IEx
  @drab_templates "priv/templates/drab"  

  @moduledoc false

  @doc false
  def render_template(filename, bindings) do
    EEx.eval_file(full_path(filename), bindings)
  end

  defp full_path(filename) do
    sources = Enum.map(paths(), &(priv_dir(&1))) |> Enum.map(&(Path.join(&1, filename)))
    Enum.find(sources, &(File.exists?(&1))) || raise "Can't find the template #{filename} in priv/templates"
  end

  defp priv_dir(app) when is_atom(app) do
    Application.app_dir(app) |> Path.join(@drab_templates)
  end
  defp priv_dir(path) when is_binary(path) do
    Path.join(path, @drab_templates)
  end

  defp paths(), do: [".", :drab]
end
