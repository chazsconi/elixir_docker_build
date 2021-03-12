defmodule DockerBuild.Build do
  @moduledoc "Generates and builds the Dockerfile"
  alias DockerBuild.DockerfileGenerator
  alias DockerBuild.Dockerfile
  alias DockerBuild.Config
  require Logger

  @doc "Generates the Dockerfile and .dockerignore and then builds the docker image"
  def run(opts) do
    config = Config.load(opts)

    DockerfileGenerator.generate_dockerignore(config)
    |> save_dockerignore()

    Mix.Shell.IO.info("Generated Dockerfile..")

    Mix.Shell.IO.info("Starting docker build..")

    DockerfileGenerator.generate_dockerfile(config)
    |> save_dockerfile()
    |> docker_build(config)
  end

  defp save_dockerfile(%Dockerfile{} = df) do
    path = "_build/Dockerfile.generated"
    File.write!(path, to_string(df))
    path
  end

  defp save_dockerignore(dockerignore) do
    File.write!(".dockerignore", Enum.join(dockerignore, "\n"))
  end

  defp docker_build(path, config) do
    # Use Mix.Shell as output is echoed to command line as it runs
    Mix.Shell.IO.cmd("docker build -f #{path} . -t #{Config.docker_image(config)}", [])
  end
end
