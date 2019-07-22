defmodule K8SDeploy.Plugins.Elm do
  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
  def extra_dockerignore do
    ~w(#{assets_source_path()}/elm_build #{assets_source_path()}/elm-stuff)
  end

  @impl K8SDeploy.Plugins
  def before_deps_get(df) do
    if config(:use_elm_install), do: install_elm_install(df), else: df
  end

  @impl K8SDeploy.Plugins
  def before_assets_compile(df) do
    if config(:use_elm_install), do: run_elm_install(df), else: df
  end

  defp install_elm_install(df) do
    df
    |> run("npm install elm-github-install -g --unsafe-perm=true --allow-root")
  end

  defp run_elm_install(df) do
    df
    |> copy("#{assets_source_path()}/elm-package.json /app/#{assets_dest_path()}/")
    |> run(["cd #{assets_dest_path()}", "elm-install"])
  end
end
