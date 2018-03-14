defmodule DrabTestApp.NodrabTest do
  use DrabTestApp.IntegrationCase

  defp nodrab_index do
    nodrab_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    nodrab_index() |> navigate_to()
    :ok
  end

  test "Drab JS should not be injected here" do
    assert execute_script("return window.Drab;") == nil
  end
end
