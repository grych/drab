defmodule Drab.Live.Safe do
  @moduledoc false
  @type t :: %Drab.Live.Safe{safe: Macro.t(), partial: Drab.Live.Partial.t()}
  defstruct safe: [], partial: %Drab.Live.Partial{}
end
