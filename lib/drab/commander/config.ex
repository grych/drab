defmodule Drab.Commander.Config do
  @moduledoc false

  defstruct commander: nil,
            controller: nil,
            view: nil,
            onload: nil,
            onconnect: nil,
            ondisconnect: nil,
            modules: Drab.Config.get(:default_modules),
            access_session: [],
            before_handler: [],
            after_handler: [],
            broadcasting: :same_path,
            public_handlers: []
end
