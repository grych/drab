defmodule Drab.Live.Commander do
  @moduledoc false

  use Drab.Commander

  # @spec save_assigns(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  # defhandler save_assigns(socket, payload) do
  #   # store assigns in Drab Server priv for caching
  #   drab = Drab.pid(socket)

  #   priv = Map.merge(Drab.get_priv(drab), payload)
  #   Drab.set_priv(drab, priv)
  #   socket
  # end

  @spec invalidate_assigns_cache(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  defhandler invalidate_assigns_cache(socket, _) do
    # invalidate the assigns cache, called after update of the partial of the page
    drab = Drab.pid(socket)
    priv = Drab.get_priv(drab)
    Drab.set_priv(drab, Map.put(priv, :assigns_cache_valid, false))
    socket
  end

  # @spec decrypted_assigns(%{}) :: %{}
  # defp decrypted_assigns(assigns) do
  #   for {partial, partial_assigns} <- assigns, into: %{} do
  #     {partial,
  #      for {name, value} <- partial_assigns, into: %{} do
  #        {name, Drab.Live.Crypto.decode64(value)}
  #      end}
  #   end
  # end
end
