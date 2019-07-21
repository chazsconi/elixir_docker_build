defmodule K8SDeploy.Build do
  import K8SDeploy.Dockerfile

  @doc "Generates the Dockerfile and .dockerignore and then builds the docker image"
  def run do
    generate_dockerignore()
    |> save_dockerignore()

    generate_dockerfile()
    |> save_dockerfile()
    |> docker_build()
  end

  defp save_dockerfile(dockerfile) do
    path = "_build/Dockerfile.generated"
    File.write!(path, dockerfile)
    path
  end

  defp save_dockerignore(dockerignore) do
    File.write!(".dockerignore", dockerignore)
  end

  defp docker_build(path) do
    # Use Mix.Shell as output is echoed to command line as it runs
    Mix.Shell.IO.cmd("docker build -f #{path} . -t #{docker_image()}", [])
  end

  defp generate_dockerfile do
    build_stage()
    |> release_stage()
    |> to_string()
  end

  defp build_stage do
    from("elixir:1.8.1 as builder")
    |> run([
      "apt-get update",
      "apt-get install -y curl",
      "curl -sL https://deb.nodesource.com/setup_8.x | bash -",
      "apt-get install -y nodejs"
    ])
    |> run(["mix local.hex --force", "mix local.rebar --force"])
    |> workdir("/app")
    |> env("MIX_ENV=prod")
    |> copy("mix.exs /app/")
    |> copy("mix.lock /app/")

    # This speeds up rebuilding the images for code changes
    # by compiling the dependencies first which should not change often
    |> run(["mix deps.get", "mix deps.compile"])

    # Speed up installing of node files
    |> copy("assets/*.json /app/assets/")
    |> run(["cd assets", "npm install"])
    |> run("mkdir -p priv/static")
    |> copy("assets /app/assets")
    |> run([
      "cd assets",
      "node_modules/webpack/bin/webpack.js --mode production --optimize-minimize"
    ])
    |> copy("/ /app")
    |> run("mix compile")
    |> run("mix phx.digest")
    |> run("mix distillery.release")
    |> run([
      "RELEASE_DIR=`ls -d _build/prod/rel/#{app_name()}/releases/*/`",
      "mkdir /export",
      "tar -xf \"$RELEASE_DIR/#{app_name()}.tar.gz\" -C /export"
    ])
  end

  def release_stage(df) do
    df
    |> from("ubuntu:bionic")
    |> run(["apt-get update", "apt-get -y install openssl"])
    |> env("LANG=C.UTF-8")
    |> copy("--from=builder /export/ /opt/app")

    # Set default entrypoint and command
    |> entrypoint(["/opt/app/bin/#{app_name()}"])
    |> cmd(["foreground"])
  end

  defp generate_dockerignore do
    ~w(*
      !/assets
      /assets/node_modules
      !/config
      !/deploy/*/keys
      !/lib
      !/priv
      /priv/static
      !/rel
      !/mix.*
    )
    |> Enum.join("\n")
  end

  defp app_name, do: config(:app_name)

  defp docker_image, do: config(:docker_image)

  defp config(key) do
    Application.get_env(:k8s_deploy, __MODULE__)[key]
  end
end
