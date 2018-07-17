defmodule DrabTestApp.LiveView do
  @moduledoc false

  use DrabTestApp.Web, :view
  @doc false
  # for testing purposes only
  # def nodrab(term), do: term

  def checkout_sms_path(_, _), do: "/"
end
