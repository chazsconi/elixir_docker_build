defmodule DockerBuild.Plugins.AssetsPlugins do
  @moduledoc """
  A behaviour for a plugin for Assets that implements additional callbacks for
  * before_assets_copy
  * asets_compile_commmand
  """

  @typedoc "The dockerfile"
  @type df() :: %DockerBuild.Dockerfile{}

  @typedoc "The dockerfile config"
  @type config() :: %DockerBuild.Config{}

  @doc """
  Invoked to discover the command to use for compiling assets.

  Only one plugin should be used that implements this function.
  """
  @callback assets_compile_command(config) :: [String.t()]

  @doc "Invoked before copying assets into the docker image"
  @callback before_assets_copy(df) :: df

  @optional_callbacks before_assets_copy: 1,
                      assets_compile_command: 1

  defmacro __using__(_opts) do
    quote do
      @behaviour DockerBuild.Plugins.AssetsPlugins

      @doc false
      def before_assets_copy(df), do: df

      @doc false
      def assets_compile_command(config), do: nil

      defoverridable DockerBuild.Plugins.AssetsPlugins
    end
  end
end
