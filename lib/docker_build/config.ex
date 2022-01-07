defmodule DockerBuild.Config do
  @moduledoc "Stores config for builder and plugins"
  alias __MODULE__
  alias DockerBuild.Dockerfile
  require Logger
  defstruct base_config: [], plugin_configs: []

  @doc """
  Load the config from the mix project

  ## Options
   * `env` - environment to be used.  Defaults to `prod`
  """
  def load(opts) do
    config =
      case Mix.Project.config()[:docker_build] do
        nil ->
          Mix.raise("Missing `:docker_build` entry in `project/0` in `mix.exs`")

        config ->
          config
      end

    env = Keyword.fetch!(opts, :env)

    plugin_configs =
      config[:plugins]
      |> Enum.map(fn
        {plugin, config} -> {plugin, config}
        plugin -> {plugin, []}
      end)
      |> add_plugin_deps()

    base_config =
      config
      |> Keyword.delete(:plugins)
      |> Keyword.put(:env, env)

    %Config{
      base_config: base_config,
      plugin_configs: plugin_configs
    }
  end

  defp add_plugin_deps(plugin_configs) do
    existing_plugins =
      plugin_configs
      |> Enum.map(fn {plugin, _} -> plugin end)

    extra_plugin_configs =
      existing_plugins
      |> Enum.reduce(MapSet.new(), fn plugin, acc ->
        MapSet.union(acc, MapSet.new(plugin.deps()))
      end)
      |> MapSet.to_list()
      |> Enum.filter(&(&1 not in existing_plugins))
      |> Enum.map(&{&1, []})

    plugin_configs ++ extra_plugin_configs
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

  @doc "Gets a list of plugins with the given dep"
  def plugins_with_dep(context, dep) do
    context
    |> plugins()
    |> Enum.filter(fn plugin -> dep in plugin.deps() end)
  end

  @doc "Get the main config for a given key - raise if it is nil"
  def config!(context, key) do
    case config(context, key) do
      nil ->
        raise ArgumentError, "Config key :#{key} is missing"

      v ->
        v
    end
  end

  @doc "Get the main config for a given key"
  def config(context, key)

  def config(%Config{base_config: base_config}, key) do
    base_config[key]
  end

  def config(%Dockerfile{config: config}, key), do: config(config, key)

  @doc "Name of the app"
  def app_name(context), do: config!(context, :app_name)

  @doc "List of umbrella apps in project"
  def umbrella_apps(context), do: config(context, :umbrella_apps) || []

  @doc "Returns `true` if the project is an umbrella app"
  def umbrella_app?(context), do: umbrella_apps(context) != nil

  @doc "Project elixir version"
  def elixir_version(context), do: config!(context, :elixir_version)

  @doc "Selected `MIX_ENV`"
  def mix_env(context), do: config!(context, :env)

  @doc "Gets the docker image"
  def docker_image(context), do: config!(context, :docker_image)

  @doc "Manager to use to create the release.  Defaults to distillery for Elixir >= 1.9.0"
  def release_manager(context) do
    case config(context, :release_manager) do
      nil ->
        if Version.compare(elixir_version(context), "1.9.0") == :lt,
          do: :distillery,
          else: :elixir

      v ->
        v
    end
  end

  @doc "The image to base the release stage on - could be made configurable"
  def release_stage_base_image(context) do
    # Before 1.9 the images use erlang:21 which is based on debian:stretch
    # Later versions use erlang:22 which is based on debian:buster
    if Version.compare(elixir_version(context), "1.9.0") == :lt,
      # Should probably be debian:stretch but this has worked so far
      do: "ubuntu:bionic",
      else: "debian:buster"

    # Or bullseye for 1.12+
  end
end
