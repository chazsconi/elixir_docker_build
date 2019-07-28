defmodule K8SDeploy.Plugins.Elm do
  @moduledoc """
  Handles Elm assets.

  To use Elm you need to configure your assets pipeline to build Elm however this plugin
  ensures the `elm_build` and `elm-stuff` folders in the assets folders
  are added to .dockerignore.

  ## Config options
   * `use_elm_install: true` - This will install [elm-install](https://github.com/gdotdesign/elm-github-install)
   and then install the elm dependencies using it.
  """

  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
  @doc "Used to add elm build paths to .dockerignore"
  def extra_dockerignore(config) do
    ~w(#{Config.assets_source_path(config)}/elm_build #{Config.assets_source_path(config)}/elm-stuff)
  end

  @impl K8SDeploy.Plugins
  @doc "Used to install elm_install"
  def before_deps_get(df) do
    if plugin_config(df, :use_elm_install), do: install_elm_install(df), else: df
  end

  @impl K8SDeploy.Plugins
  @doc "Used to run elm_install"
  def before_assets_copy(df) do
    if plugin_config(df, :use_elm_install), do: run_elm_install(df), else: df
  end

  defp install_elm_install(df) do
    df
    |> run("npm install elm-github-install -g --unsafe-perm=true --allow-root")
  end

  defp run_elm_install(df) do
    df
    |> copy("#{Config.assets_source_path(df)}/elm-package.json #{Config.assets_dest_path(df)}/")
    |> run(["cd #{Config.assets_dest_path(df)}", "elm-install"])
  end
end
