defmodule DrabTestApp.NodrabTest do
  use DrabTestApp.IntegrationCase

  defp nodrab_index do
    nodrab_url(DrabTestApp.Endpoint, :index)
  end

  setup do
    navigate_to(nodrab_index())
    :ok
  end

  test "Drab JS should not be injected here" do
    assert execute_script("return window.Drab;") == nil
  end
end
