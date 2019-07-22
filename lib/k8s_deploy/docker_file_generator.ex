defmodule K8SDeploy.DockerfileGenerator do
  @moduledoc "Generates a Dockerfile and .dockerignore"
  import K8SDeploy.Dockerfile
  alias K8SDeploy.Config
  require Logger

  @doc "Generates the Dockerfile returning `%Dockerfile{}`"
  def generate_dockerfile(%Config{} = config) do
    new(config)
    |> build_stage()
    |> release_stage()
  end

  @doc "Generates the .dockerignore returning a list of entries"
  def generate_dockerignore(%Config{} = config) do
    base_docker_ignore(config) ++ plugins_extra_dockerignore(config) ++ extra_dockerignore(config)
  end

  defp build_stage(df) do
    df
    |> from("elixir:#{Config.elixir_version(df)} as builder")
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
      "RELEASE_DIR=`ls -d _build/prod/rel/#{Config.app_name(df)}/releases/*/`",
      "mkdir /export",
      "tar -xf \"$RELEASE_DIR/#{Config.app_name(df)}.tar.gz\" -C /export"
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
      Config.plugins(df)
      |> Enum.reduce({df, []}, fn plugin, {df, plugins} ->
        case plugin.assets_compile_command(df) do
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
    Config.plugins(df)
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
    |> entrypoint(["/opt/app/bin/#{Config.app_name(df)}"])
    |> cmd(["foreground"])
  end

  defp base_docker_ignore(_config) do
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

  def plugins_extra_dockerignore(config) do
    Config.plugins(config)
    |> Enum.map(& &1.extra_dockerignore(config))
    |> List.flatten()
  end

  defp extra_dockerignore(config) do
    Config.config(config, :extra_dockerignore) || []
  end
end
