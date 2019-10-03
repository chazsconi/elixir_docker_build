defmodule Mix.Tasks.Docker.Build do
  use Mix.Task
  alias DockerBuild.Build

  @shortdoc "Builds a docker image for the project"

  @moduledoc """
  Builds a new docker image for the project for a given enviroment.  Defaults to `:prod`

  ## Example

  `mix docker.build dev`
  """

  @doc false
  def run(args) do
    {:ok, env} =
      case args do
        [] ->
          {:ok, :prod}

        [env] ->
          {:ok, env}

        _ ->
          Mix.raise("Too many parameters")
          :error
      end

    Mix.shell().info("Using env #{env}")

    case Build.run(env: env) do
      0 -> Mix.shell().info("Build done")
      n -> Mix.raise("Build failed. Exit code #{n}")
    end
  end
end
