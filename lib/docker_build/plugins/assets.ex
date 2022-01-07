defmodule DockerBuild.Plugins.Assets do
  @moduledoc """
  Installs and compiles assets
  """
  use DockerBuild.Plugins
  require Logger

  @impl DockerBuild.Plugins
  def extra_dockerignore(config) do
    ~w(
      !#{assets_source_path(config)}
      #{assets_source_path(config)}/node_modules
      )
  end

  @impl DockerBuild.Plugins
  def install_build_deps(df) do
    df
    |> run([
      "apt-get update",
      "apt-get install -y curl",
      "curl -sL https://deb.nodesource.com/setup_12.x | bash -",
      "apt-get install -y nodejs"
    ])
  end

  @impl DockerBuild.Plugins
  def before_source_copy(df) do
    df
    |> install_assets_deps()
    |> before_assets_copy()
    |> copy_assets()
    |> compile_assets()
  end

  defp install_assets_deps(df) do
    source = assets_source_path(df)
    dest = assets_dest_path(df)

    df
    |> copy("#{source}/*.json #{dest}/")
    |> run(["cd #{dest}", "npm install"])
  end

  defp before_assets_copy(df) do
    assets_plugins(df)
    |> Enum.reduce(df, fn plugin, df ->
      plugin.before_assets_copy(df)
    end)
  end

  defp copy_assets(df) do
    source = assets_source_path(df)
    dest = assets_dest_path(df)

    df
    |> run("mkdir -p priv/static")
    |> copy("#{source} #{dest}")
  end

  defp compile_assets(df) do
    {df, plugins} =
      assets_plugins(df)
      |> Enum.reduce({df, []}, fn plugin, {df, plugins} ->
        case plugin.assets_compile_command(df) do
          nil -> {df, plugins}
          command -> {run(df, command), [plugin | plugins]}
        end
      end)

    case plugins do
      [] ->
        Logger.warn("No asset compile command given")

      [_] ->
        :ok

      _ ->
        Logger.warn("Multiple asset compile commands given from #{inspect(plugins)}")
    end

    df
  end

  defp assets_plugins(context) do
    Config.plugins_with_dep(context, __MODULE__)
  end

  # Path to assets within project.  Defaults to `assets`
  def assets_path(context) do
    path = plugin_config(context, :assets_path) || "assets"
    String.trim_leading(path, "/")
  end

  @doc "Source path of assets (used for docker `COPY`)"
  def assets_source_path(context), do: "/" <> assets_path(context)

  @doc "Destination path of assets in docker build image"
  def assets_dest_path(context), do: "/app/#{assets_path(context)}"
end
