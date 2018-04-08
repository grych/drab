defmodule Drab.Live.Commander do
  @moduledoc false
  use Drab.Commander

  @spec invalidate_assigns_cache(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  defhandler invalidate_assigns_cache(socket, _) do
    # invalidate the assigns cache, called after update of the partial of the page
    drab = Drab.pid(socket)
    priv = Drab.get_priv(drab)
    Drab.set_priv(drab, Map.put(priv, :assigns_cache_valid, false))
    socket
  end
end
