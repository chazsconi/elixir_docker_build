defmodule DockerBuild.DockerfileGenerator do
  @moduledoc "Generates a Dockerfile and .dockerignore"
  import DockerBuild.Dockerfile
  alias DockerBuild.Config
  require Logger

  @doc "Generates the Dockerfile returning `%Dockerfile{}`"
  def generate_dockerfile(%Config{} = config) do
    new(config)
    |> build_stage()
    |> release_stage()
  end

  @doc "Generates the .dockerignore returning a list of entries"
  def generate_dockerignore(%Config{} = config) do
    base_docker_ignore(config) ++
      umbrella_app_docker_ignore(config) ++
      plugins_extra_dockerignore(config) ++
      extra_dockerignore(config)
  end

  defp build_stage(df) do
    df
    |> from("elixir:#{Config.elixir_version(df)} as builder")
    |> install_build_deps()
    |> run(["mix local.hex --force", "mix local.rebar --force"])
    |> copy_ssh_keys()
    |> copy_netrc()
    |> before_deps_get()
    |> workdir("/app")
    |> env("MIX_ENV=#{Config.mix_env(df)}")
    |> copy("mix.* /app/")
    |> copy_umbrella_app_mix_files(Config.umbrella_apps(df))

    # This speeds up rebuilding the images for code changes
    # by compiling the dependencies first which should not change often
    |> run(["mix deps.get", "mix deps.compile"])

    # Speed up installing of node files
    |> before_source_copy()
    |> copy("/ /app")
    |> run("mix compile")
    |> run("mix phx.digest")
    |> build_release(Config.release_manager(df))
    |> export_release(Config.release_manager(df))
  end

  defp copy_umbrella_app_mix_files(df, []), do: df

  defp copy_umbrella_app_mix_files(df, [umbrella_app | rest]) do
    df
    |> copy("/apps/#{umbrella_app}/mix.exs /app/apps/#{umbrella_app}/")
    |> copy_umbrella_app_mix_files(rest)
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

  defp copy_netrc(df) do
    if File.exists?("deploy/.netrc") do
      df
      |> copy("deploy/.netrc /root/")
    else
      df
    end
  end

  defp build_release(df, :distillery), do: run(df, "mix distillery.release")
  defp build_release(df, :elixir), do: run(df, "mix release")

  defp export_release(df, :distillery) do
    df
    |> run([
      "RELEASE_DIR=`ls -d _build/#{Config.mix_env(df)}/rel/#{Config.app_name(df)}/releases/*/`",
      "mkdir /export",
      "tar -xf \"$RELEASE_DIR/#{Config.app_name(df)}.tar.gz\" -C /export"
    ])
  end

  defp export_release(df, :elixir) do
    df
    |> run("mv _build/#{Config.mix_env(df)}/rel/#{Config.app_name(df)} /export")
  end

  defp install_build_deps(df) do
    Config.plugins(df)
    |> Enum.reduce(df, fn plugin, df ->
      plugin.install_build_deps(df)
    end)
  end

  defp before_deps_get(df) do
    Config.plugins(df)
    |> Enum.reduce(df, fn plugin, df ->
      plugin.before_deps_get(df)
    end)
  end

  defp before_source_copy(df) do
    Config.plugins(df)
    |> Enum.reduce(df, fn plugin, df ->
      plugin.before_source_copy(df)
    end)
  end

  def release_stage(df) do
    df
    |> from(Config.release_stage_base_image(df))
    |> run(["apt-get update", "apt-get -y install openssl"])
    |> env("LANG=C.UTF-8")
    |> copy("--from=builder /export/ /opt/app")
    # Set default entrypoint and command
    |> (fn df ->
          if Config.release_manager(df) == :distillery do
            df
            |> entrypoint(["/opt/app/bin/#{Config.app_name(df)}"])
            |> cmd(["foreground"])
          else
            df
            |> cmd(["/opt/app/bin/#{Config.app_name(df)}", "start"])
          end
        end).()
  end

  defp base_docker_ignore(_config) do
    ~w(*
      !/apps
      !/config
      !/deploy/ssh_keys
      !/deploy/.netrc
      !/lib
      !/priv
      /priv/static
      !/rel
      !/mix.*
    )
  end

  def umbrella_app_docker_ignore(config) do
    Config.umbrella_apps(config)
    |> Enum.map(&"/apps/#{&1}/priv/static")
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
