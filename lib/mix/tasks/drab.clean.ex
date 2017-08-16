defmodule Mix.Tasks.Drab.Clean do
  use Mix.Task

  @shortdoc "Clean up compiled binaries and the Drab cache"

  @moduledoc """
  A task to clean up both compiled binaries and the Drab cache. Use it instead of `mix clean`
  """

  # @env Mix.env()
  # defp env(), do: @env
  
  @doc false
  def run(args) do
    # File.rm "priv/hashes_expressions.drab.cache.#{env()}"
    File.rm Drab.Live.Cache.cache_file()
    Mix.Task.run("clean", args)
  end

end
