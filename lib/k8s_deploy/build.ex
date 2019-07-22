defmodule K8SDeploy.Build do
  import K8SDeploy.Dockerfile
  require Logger

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
    from("elixir:#{elixir_version()} as builder")
    |> run([
      "apt-get update",
      "apt-get install -y curl",
      "curl -sL https://deb.nodesource.com/setup_8.x | bash -",
      "apt-get install -y nodejs"
    ])
    |> run(["mix local.hex --force", "mix local.rebar --force"])
    |> copy_ssh_keys()
    |> before_deps_get()
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
    |> compile_assets()
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

  defp copy_ssh_keys(df) do
    if File.exists?("deploy/ssh_keys") do
      df
      |> copy("deploy/ssh_keys/* /root/.ssh/")
      |> run("chmod 400 /root/.ssh/*_rsa")
    else
      df
    end
  end

  defp compile_assets(df) do
    {df, plugins} =
      plugins()
      |> Enum.reduce({df, []}, fn plugin, {df, plugins} ->
        case plugin.assets_compile_command() do
          nil -> {df, plugins}
          command -> {run(df, command), [plugin | plugins]}
        end
      end)

    case plugins do
      [] ->
        Logger.warn("No asset compile command given")

      [_] ->
        :ok

      _ ->
        Logger.warn("Multiple asset compile commands given from #{inspect(plugins)}")
    end

    df
  end

  defp before_deps_get(df) do
    plugins()
    |> Enum.reduce(df, fn plugin, df ->
      plugin.before_deps_get(df)
    end)
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
    patterns = base_docker_ignore() ++ plugins_extra_dockerignore() ++ extra_dockerignore()
    Enum.join(patterns, "\n")
  end

  defp base_docker_ignore do
    ~w(*
      !/assets
      /assets/node_modules
      !/config
      !/deploy/ssh_keys
      !/lib
      !/priv
      /priv/static
      !/rel
      !/mix.*
    )
  end

  def plugins_extra_dockerignore do
    plugins()
    |> Enum.map(& &1.extra_dockerignore())
    |> List.flatten()
  end

  defp extra_dockerignore do
    config(:extra_dockerignore) || []
  end

  def assets_source_path, do: "/assets"
  def assets_dest_path, do: "/app/assets"

  defp plugins do
    config(:plugins)
    |> Enum.map(fn
      {mod, _config} -> mod
      mod -> mod
    end)
  end

  def app_name, do: config(:app_name)
  defp elixir_version, do: config(:elixir_version)
  defp docker_image, do: config(:docker_image)

  defp config(key) do
    Application.get_env(:k8s_deploy, __MODULE__)[key]
  end
end
