defmodule Drab.Live.Commander do
  @moduledoc false

  use Drab.Commander

  @spec save_assigns(Phoenix.Socket.t(), map) :: Phoenix.Socket.t()
  defhandler save_assigns(socket, payload) do
    # store assigns in Drab Server
    drab = Drab.pid(socket)
    # IO.inspect(decrypted_assigns(payload["__assigns"]))
    # decrypted_assigns(payload["__assigns"])
    # Process.sleep 50

    priv =
      Map.merge(Drab.get_priv(drab), %{
        # __ampere_assigns: decrypted_assigns(payload["__assigns"]),
        __ampere_assigns: payload["__assigns"],
        __amperes: payload["__amperes"],
        __index: payload["__index"]
      })

    drab |> Drab.set_priv(priv)
    socket
  end

  @spec decrypted_assigns(%{}) :: %{}
  def decrypted_assigns(assigns) do
    for {partial, partial_assigns} <- assigns, into: %{} do
      {partial,
       for {name, value} <- partial_assigns, into: %{} do
         {name, Drab.Live.Crypto.decode64(value)}
       end}
    end
  end
end
