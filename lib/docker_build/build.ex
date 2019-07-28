defmodule DockerBuild.Build do
  @moduledoc "Generates and builds the Dockerfile"
  alias DockerBuild.DockerfileGenerator
  alias DockerBuild.Dockerfile
  alias DockerBuild.Config
  require Logger

  @doc "Generates the Dockerfile and .dockerignore and then builds the docker image"
  def run(opts) do
    config = Config.load_from_application_env(opts)

    DockerfileGenerator.generate_dockerignore(config)
    |> save_dockerignore()

    Mix.Shell.IO.info("Generated Dockerfile..")

    Mix.Shell.IO.info("Starting docker build..")

    DockerfileGenerator.generate_dockerfile(config)
    |> save_dockerfile()
    |> docker_build()
  end

  defp save_dockerfile(%Dockerfile{} = df) do
    path = "_build/Dockerfile.generated"
    File.write!(path, to_string(df))
    path
  end

  defp save_dockerignore(dockerignore) do
    File.write!(".dockerignore", Enum.join(dockerignore, "\n"))
  end

  defp docker_build(path) do
    # Use Mix.Shell as output is echoed to command line as it runs
    Mix.Shell.IO.cmd("docker build -f #{path} . -t #{docker_image()}", [])
  end

  defp docker_image, do: config(:docker_image)

  defp config(key) do
    Application.get_env(:docker_build, __MODULE__)[key]
  end
end
