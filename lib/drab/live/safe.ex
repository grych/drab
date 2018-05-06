defmodule Drab.Live.Safe do
  @moduledoc false
  @type t :: %Drab.Live.Safe{safe: Macro.t(), shadow: Macro.t(), partial: Drab.Live.Partial.t()}
  defstruct safe: [], shadow: [], partial: %Drab.Live.Partial{}
end
