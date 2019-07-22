defmodule K8SDeploy.Plugins.Brunch do
  @moduledoc "Compiles assets using Brunch"
  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
  def assets_compile_command do
    [
      "#{assets_dest_path()}/node_modules/brunch/bin/brunch build --production #{
        assets_dest_path()
      }"
    ]
  end
end
