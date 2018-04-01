defmodule Drab.Live.Commander do
  @moduledoc false

  use Drab.Commander

  @spec save_assigns(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  defhandler save_assigns(socket, payload) do
    # store assigns in Drab Server
    drab = Drab.pid(socket)

    priv = Map.merge(Drab.get_priv(drab), payload)
    Drab.set_priv(drab, priv)
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
