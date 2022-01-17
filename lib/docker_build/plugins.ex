defmodule DockerBuild.Plugins do
  @moduledoc """
  A behaviour for a plugin system allowing functionality to be extended when building the docker image.

  By implementing the optional callbacks the docker file can be changed at various points.

  All callbacks are optional.

  ## Creating a plugin

  1. Create module e.g. `MyProject.MyPlugin`
  2. Add `use DockerBuild.Plugins`
  3. Implement the required callbacks to modify the docker file or `.dockerignore`
  4. To fetch a plugin config value with the plugin callback use `plugin_config(context, key)` where
  `context` is either the `config` or `df` parameter passed to the callback.
  """

  @typedoc "The dockerfile"
  @type df() :: %DockerBuild.Dockerfile{}

  @typedoc "The dockerfile config"
  @type config() :: %DockerBuild.Config{}

  @doc "Dependent plugins"
  @callback deps() :: [module()]

  @doc """
  Invoked when creating the .dockerignore file.

  A list of addition lines can be returned which are added to the file.
  """
  @callback extra_dockerignore(config) :: [String.t()]

  @doc "Invoked at start to install any build dependencies - e.g linux packages"
  @callback install_build_deps(df) :: df

  @doc "Invoked before copying all source files"
  @callback before_source_copy(df) :: df

  @doc "Invoked before getting mix dependencies"
  @callback before_deps_get(df) :: df

  @optional_callbacks deps: 0,
                      install_build_deps: 1,
                      extra_dockerignore: 1,
                      before_deps_get: 1,
                      before_source_copy: 1

  defmacro __using__(_opts) do
    quote do
      import DockerBuild.Dockerfile
      alias DockerBuild.Config
      @behaviour DockerBuild.Plugins

      @doc false
      def deps, do: []

      @doc false
      def extra_dockerignore(config), do: []

      @doc false
      def install_build_deps(df), do: df

      @doc false
      def before_deps_get(df), do: df

      @doc false
      def before_source_copy(df), do: df

      @doc false
      def plugin_config(context, key), do: Config.plugin_config(context, __MODULE__, key)

      defoverridable DockerBuild.Plugins
    end
  end
end
