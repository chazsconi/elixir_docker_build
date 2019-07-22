defmodule K8SDeploy.Build do
  @moduledoc "Generates and builds the Dockerfile"
  alias K8SDeploy.DockerfileGenerator
  alias K8SDeploy.Dockerfile
  alias K8SDeploy.Config
  require Logger

  @doc "Generates the Dockerfile and .dockerignore and then builds the docker image"
  def run do
    config = Config.load_from_application_env()

    DockerfileGenerator.generate_dockerignore(config)
    |> save_dockerignore()

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
    Application.get_env(:k8s_deploy, __MODULE__)[key]
  end
end
