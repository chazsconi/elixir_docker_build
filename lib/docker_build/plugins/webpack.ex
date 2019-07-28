defmodule DockerBuild.Plugins.Webpack do
  @moduledoc """
  Complies assets using webpack
  """
  use DockerBuild.Plugins

  @impl DockerBuild.Plugins
  def assets_compile_command(config) do
    [
      "cd #{Config.assets_dest_path(config)}",
      "node_modules/webpack/bin/webpack.js --mode production --optimize-minimize"
    ]
  end
end
