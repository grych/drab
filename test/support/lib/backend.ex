defmodule DrabTestApp.Backend do
  @moduledoc false

  # PubSub support
    @topic inspect(__MODULE__)
    
    def subscribe() do
    	Phoenix.PubSub.subscribe(DrabTestApp.PubSub, @topic)
    end

    defp notify_subscribers({:ok, result}, event) do
      Phoenix.PubSub.broadcast(DrabTestApp.PubSub, @topic, {__MODULE__, event, result})
      {:ok, result}
    end

    defp notify_subscribers({:error, reason}, _event), do: {:error, reason}

  # Fake db access
    @fake_db [1, 2, 3]

    def get_data() do
    	@fake_db
    end

    def append_element(element) do
      get_data()
      |> List.insert_at(-1, element)
      |> (&({:ok, &1})).()
      |> notify_subscribers([:data, :updated])
    end
end