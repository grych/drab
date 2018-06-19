defmodule Drab.Presence do
  @moduledoc """

  """

  # this is because of the wrong specs in Phx <=1.3.3
  # TODO: remove nowarn when Phx release specs
  @dialyzer {:nowarn_function, init: 1}

  use Phoenix.Presence,
    otp_app: Drab.Config.app_name(),
    pubsub_server: Drab.Config.pubsub()

  def track(socket) do
    client_id =
      Drab.Core.get_session(socket, Drab.Config.get(:presence, :id)) || Drab.Browser.id!(socket)

    {:ok, _} =
      track(socket, client_id, %{
        online_at: System.system_time(:seconds)
      })
  end

  def count_users(topic), do: Enum.count(list(topic))

  def count_connections(topic) do
    for {_, %{metas: metas}} <- list(topic) do
      Enum.count(metas)
    end
    |> Enum.sum()
  end
end
