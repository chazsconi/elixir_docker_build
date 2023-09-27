defmodule Mix.Tasks.Docker.Build do
  use Mix.Task
  alias DockerBuild.Build

  @shortdoc "Builds a docker image for the project"

  @moduledoc """
  Builds a new docker image for the project for a given enviroment.  Defaults to `:prod`

  ## Example

  `mix docker.build dev`

  ## Options
   * `--target` - stage to build.  Can be "builder" or "release".  Defaults to "release"
   * `--no-build` - just generate the Dockerfile and do not build
  """

  @doc false
  def run(args) do
    {:ok, opts} =
      case OptionParser.parse!(args, strict: [target: :string, no_build: :boolean]) do
        {opts, []} ->
          {:ok, opts}

        {opts, [env]} ->
          {:ok, [{:env, env} | opts]}

        _ ->
          Mix.raise("Too many parameters")
          :error
      end

    case Build.run(opts) do
      0 -> Mix.shell().info("Build done")
      n -> Mix.raise("Build failed. Exit code #{n}")
    end
  end
end
