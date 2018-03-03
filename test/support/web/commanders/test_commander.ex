defmodule DrabTestApp.TestCommander do
  use Drab.Commander, modules: [Drab.Query]
  onload(:onload_function)
end
