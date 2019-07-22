defmodule K8SDeploy.Plugins.Elm do
  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
  def extra_dockerignore(config) do
    ~w(#{Config.assets_source_path(config)}/elm_build #{Config.assets_source_path(config)}/elm-stuff)
  end

  @impl K8SDeploy.Plugins
  def before_deps_get(df) do
    if plugin_config(df, :use_elm_install), do: install_elm_install(df), else: df
  end

  @impl K8SDeploy.Plugins
  def before_assets_compile(df) do
    if plugin_config(df, :use_elm_install), do: run_elm_install(df), else: df
  end

  defp install_elm_install(df) do
    df
    |> run("npm install elm-github-install -g --unsafe-perm=true --allow-root")
  end

  defp run_elm_install(df) do
    df
    |> copy(
      "#{Config.assets_source_path(df)}/elm-package.json /app/#{Config.assets_dest_path(df)}/"
    )
    |> run(["cd #{Config.assets_dest_path(df)}", "elm-install"])
  end
end
