defmodule DrabTestApp.LiveView do
  @moduledoc false
  
  use DrabTestApp.Web, :view

  def dupa(x, _y), do: "dupa ----------- #{x}"
end
