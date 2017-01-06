defmodule Phoenix.Channel do
  def push(socket, command,  %{js: js, sender: sender}) do
    
  end
end

# defmodule Phoenix.Token do
#   # def get_key_base(_) do
#   #   "keybase"
#   # end
#   def sign(_, _, pid_binary) do
#     pid_binary
#   end
# end

defmodule Drab.Endpoint do
  def config(:secret_key_base) do
    "qw2PXBwSRhlpxcOkJbatD+oMf+27pSfeaO9Uy0G/AI776Qx5K5ncyH9ZaSBVng5F"
  end
end

defmodule Drab.QueryTest do
  use ExUnit.Case
  doctest Drab.Query

  def socket() do
    %Phoenix.Socket{
      endpoint: Drab.Endpoint
    }
  end

  test "this/1 should return drab_id" do
    dom_sender = %{ "drab_id" => "DRAB_ID"}
    assert Drab.Query.this(dom_sender) == "[drab-id=DRAB_ID]"
  end

  test "tokenize should " do
    assert Drab.Query.tokenize(socket, self()) == "dupa" #:erlang.term_to_binary(self())
    # assert Drab.Query.select(socket, :val, from: "non-existent") == []
  end
end
