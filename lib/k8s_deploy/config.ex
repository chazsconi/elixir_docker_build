defmodule K8SDeploy.Config do
  @moduledoc "Stores config for builder and plugins"
  alias __MODULE__
  alias K8SDeploy.Dockerfile
  defstruct base_config: [], plugin_configs: []

  @doc "Load the config from the application env"
  def load_from_application_env do
    config = Application.get_env(:k8s_deploy, K8SDeploy.Build)

    plugin_configs =
      config[:plugins]
      |> Enum.map(fn
        {plugin, config} -> {plugin, config}
        plugin -> {plugin, Application.get_env(:k8s_deploy, plugin, [])}
      end)

    %Config{base_config: Keyword.delete(config, :plugins), plugin_configs: plugin_configs}
  end

  @doc "Get the config for a given plugin and key"
  def plugin_config(context, plugin, key)

  def plugin_config(%Config{plugin_configs: plugin_configs}, plugin, key) do
    plugin_configs[plugin][key]
  end

  def plugin_config(%Dockerfile{config: config}, plugin, key),
    do: plugin_config(config, plugin, key)

  @doc "Get a list of plugins"
  def plugins(context)

  def plugins(%Dockerfile{config: config}), do: plugins(config)

  def plugins(%Config{plugin_configs: plugin_configs}) do
    Keyword.keys(plugin_configs)
  end

  @doc "Get the main config for a given key"
  def config(context, key)

  def config(%Config{base_config: base_config}, key) do
    base_config[key]
  end

  def config(%Dockerfile{config: config}, key), do: config(config, key)

  def assets_source_path(_), do: "/assets"
  def assets_dest_path(_), do: "/app/assets"

  def app_name(context), do: config(context, :app_name)
  def elixir_version(context), do: config(context, :elixir_version)
end
