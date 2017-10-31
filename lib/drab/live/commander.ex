defmodule Drab.Live.Commander do
  @moduledoc false

  use Drab.Commander
  public :save_assigns

  def save_assigns(socket, payload) do
    # store assigns in Drab Server
    drab = Drab.pid(socket)
    priv = Map.merge(Drab.get_priv(drab), %{
      __ampere_assigns: payload["__assigns"],
      __amperes: payload["__amperes"],
      __index:   payload["__index"]
    })
    drab |> Drab.set_priv(priv)
    socket
  end
end
