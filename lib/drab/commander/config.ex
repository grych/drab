defmodule Drab.Commander.Config do
  @moduledoc false

  defstruct commander: nil, 
    onload: nil,
    onconnect: nil,
    ondisconnect: nil,
    # by default load Drab.Query and Drab.Modal
    modules: [Drab.Query, Drab.Modal],
    access_session: [],
    before_handler: [],
    after_handler: []
end
