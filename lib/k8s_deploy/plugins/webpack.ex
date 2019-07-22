defmodule K8SDeploy.Plugins.Webpack do
  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
  def assets_compile_command do
    [
      "cd #{assets_dest_path()}",
      "node_modules/webpack/bin/webpack.js --mode production --optimize-minimize"
    ]
  end
end
