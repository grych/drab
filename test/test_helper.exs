defmodule DrabTestApp.TestHelper do
  def phantomjs_path() do
    # {"/opt/local/bin/phantomjs\n", 0}
    {path, ret} = System.cmd("which", ["phantomjs"])
    if path == "" || ret != 0 do
      raise """
      Can't find phantomjs in the system.
      Please check if it is installed and it is in the PATH.
      """
    end
    String.strip(path)
  end
end

if Mix.env == :test do
  Application.put_env(:wallaby, :base_url, DrabTestApp.Endpoint.url)
  Application.put_env(:wallaby, :phantomjs, DrabTestApp.TestHelper.phantomjs_path())

  ExUnit.start()
  {:ok, _} = Application.ensure_all_started(:wallaby)
end
