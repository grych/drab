# defmodule DrabTestApp.TestHelper do
#   @moduledoc false
#   def phantomjs_path() do
#     # {"/opt/local/bin/phantomjs\n", 0}
#     {path, ret} = System.cmd("which", ["phantomjs"])
#     if path == "" || ret != 0 do
#       raise """
#       Can't find phantomjs in the system.
#       Please check if it is installed and it is in the PATH.
#       """
#     end
#     String.strip(path)
#   end
# end


{:ok, _} = Application.ensure_all_started(:hound)
ExUnit.start()
