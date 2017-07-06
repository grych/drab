defmodule Mix.Tasks.Compile.Drab do
  use Mix.Task
  @recursive true

  # This module is not used so far (0.4.0)

  @moduledoc false

  @doc false
  def run(_args) do
    IO.puts "Compiling Drab templates"
    Code.compiler_options(ignore_module_conflict: true)
    Kernel.ParallelCompiler.files([Drab.Template.__info__(:compile)[:source] |> List.to_string])
    Code.compiler_options(ignore_module_conflict: false)
    :ok
  end
end
