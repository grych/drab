defmodule Drab.Live.Partial do
  @moduledoc false
  @type t :: %Drab.Live.Partial{name: String.t(), hash: String.t(), amperes_assigns: map}
  defstruct name: "", hash: "", amperes_assigns: %{}
end
