defmodule K8SDeploy.Plugins do
  @type df() :: %K8SDeploy.Dockerfile{}

  @callback extra_dockerignore() :: [String.t()]

  @callback assets_compile_command() :: [String.t()]

  @callback before_deps_get(df) :: df

  @callback before_assets_compile(df) :: df

  defmacro __using__(_opts) do
    quote do
      import K8SDeploy.Dockerfile
      import K8SDeploy.Build, only: [assets_source_path: 0, assets_dest_path: 0]
      @behaviour K8SDeploy.Plugins

      def config(key) do
        inline_config =
          Application.get_env(:k8s_deploy, K8SDeploy.Build)[:plugins]
          |> Enum.find(fn
            {mod, config} -> mod == __MODULE__
            _ -> false
          end)

        config =
          case inline_config do
            {_, config} -> config
            _ -> Application.get_env(:k8s_deploy, __MODULE__)
          end

        config[key]
      end

      def extra_dockerignore, do: []
      def assets_compile_command, do: nil
      def before_deps_get(df), do: df
      def before_assets_compile(df), do: df

      defoverridable K8SDeploy.Plugins
    end
  end
end
