defmodule K8SDeploy.Plugins do
  @type df() :: %K8SDeploy.Dockerfile{}
  @type config() :: %K8SDeploy.Config{}

  @callback extra_dockerignore(config) :: [String.t()]

  @callback assets_compile_command(config) :: [String.t()]

  @callback before_deps_get(df) :: df

  @callback before_assets_compile(df) :: df

  defmacro __using__(_opts) do
    quote do
      import K8SDeploy.Dockerfile
      alias K8SDeploy.Config
      @behaviour K8SDeploy.Plugins

      def extra_dockerignore(config), do: []
      def assets_compile_command(config), do: nil
      def before_deps_get(df), do: df
      def before_assets_compile(df), do: df

      def plugin_config(context, key), do: Config.plugin_config(context, __MODULE__, key)

      defoverridable K8SDeploy.Plugins
    end
  end
end
