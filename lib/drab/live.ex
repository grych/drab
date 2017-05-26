defmodule Drab.Live do
  @moduledoc false

  use DrabModule
  def js_templates(),  do: ["drab.events.js", "drab.live.js"]

  def transform_payload(payload) do
    # decrypt assigns
    decrypted = for {k, v} <- payload["assigns"], into: %{}, do: {k, Drab.Live.Crypto.decode(v)}
    Map.merge(payload, %{"assigns" => decrypted})
  end

  def transform_socket(socket, payload) do
    # store assigns in socket as well
    Phoenix.Socket.assign(socket, :__ampere_assigns, payload["assigns"])
  end

  # engine: Drab.Live.EExEngine
  def render_live(template, assigns \\ []) do
    EEx.eval_file(template, [assigns: assigns], engine: Drab.Live.EExEngine)
  end
end
