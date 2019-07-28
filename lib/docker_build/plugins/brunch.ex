defmodule DockerBuild.Plugins.Brunch do
  @moduledoc "Compiles assets using Brunch"
  use DockerBuild.Plugins

  @impl DockerBuild.Plugins
  def assets_compile_command(config) do
    [
      "#{Config.assets_dest_path(config)}/node_modules/brunch/bin/brunch build --production #{
        Config.assets_dest_path(config)
      }"
    ]
  end
end
