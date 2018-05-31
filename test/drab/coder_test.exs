defmodule Drab.CoderTest do
  use ExUnit.Case, ascync: true
  doctest Drab.Coder.Base64
  doctest Drab.Coder.URL
  doctest Drab.Coder.Cipher
  doctest Drab.Coder.String
  doctest Drab.Coder
end
