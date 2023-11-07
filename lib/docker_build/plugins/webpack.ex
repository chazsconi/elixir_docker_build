defmodule DockerBuild.Plugins.Webpack do
  @moduledoc """
  Complies assets using webpack
  This supports Webpack >= v4
  """
  use DockerBuild.Plugins
  use DockerBuild.Plugins.AssetsPlugins
  alias DockerBuild.Plugins.Assets

  @impl DockerBuild.Plugins
  def deps, do: [Assets]

  @impl DockerBuild.Plugins.AssetsPlugins
  def assets_compile_command(config) do
    [
      "cd #{Assets.assets_dest_path(config)}",
      "node_modules/webpack/bin/webpack.js --mode production"
    ]
  end
end
