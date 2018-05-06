defmodule Drab.Live.Ampere do
  @moduledoc false
  # {:html | :prop | :attr, "tag", "prop_or_attr", expression, [:assigns], [:children]}
  @type t :: %Drab.Live.Ampere{
          gender: atom,
          tag: String.t(),
          attribute: String.t(),
          assigns: list
        }
  defstruct gender: :unknown, tag: "", attribute: "", assigns: []
end
