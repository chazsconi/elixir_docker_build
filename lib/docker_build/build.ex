defmodule DockerBuild.Build do
  @moduledoc "Generates and builds the Dockerfile"
  alias DockerBuild.DockerfileGenerator
  alias DockerBuild.Dockerfile
  alias DockerBuild.Config
  require Logger

  @supported_base_image_os_list ~w(debian:buster debian:bullseye)
  @doc "Generates the Dockerfile and .dockerignore and then builds the docker image"
  def run(opts) do
    config =
      opts
      |> Config.load()
      |> set_release_stage_base_image()

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
    if Config.build?(config) do
      tag =
        case Config.target(config) do
          "release" -> Config.docker_image(config)
          "builder" -> Config.docker_image(config) <> "-builder"
        end

      # Use Mix.Shell as output is echoed to command line as it runs
      cmd = "docker build -f #{path} . -t #{tag} --target #{Config.target(config)}"

      Logger.info("Executing #{cmd}")
      Mix.Shell.IO.cmd(cmd, [])
    else
      Logger.info("Skipping build")
      # Return 0 exit code
      0
    end
  end

  # As the build stage base image needs to match the release stage base image OS, we
  # do a 'docker run' on the build stage image to determine the OS, and set this as the base image for
  # the release stage
  defp set_release_stage_base_image(config) do
    case get_build_stage_base_image_os(config) do
      {build_image_os, 0} when build_image_os in @supported_base_image_os_list ->
        Mix.Shell.IO.info(
          "Build stage base image OS is #{build_image_os}.  Will use same for release stage base image."
        )

        Config.set_release_stage_base_image(config, build_image_os)

      {build_image_os, 0} ->
        Mix.raise(
          "Build stage base image OS unsupported #{inspect(build_image_os)} - supported are: #{Enum.join(@supported_base_image_os_list, ",")}"
        )

      {_, exit_code} ->
        Mix.raise("Could not determine build stage base image OS - exit code: #{exit_code}")
    end
  end

  defp get_build_stage_base_image_os(config) do
    # This should return something like 'debian:buster'
    bash_cmd = "source /etc/os-release && echo -n $ID:$VERSION_CODENAME"

    cmd = ~s|docker run --rm elixir:#{Config.elixir_version(config)} bash -c '#{bash_cmd}'|

    System.cmd("bash", ["-c", cmd])
  end
end
