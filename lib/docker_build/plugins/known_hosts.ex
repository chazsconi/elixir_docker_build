defmodule DockerBuild.Plugins.KnownHosts do
  @moduledoc """
  Adds a a list of hosts provided in the `:hosts` config to `~/.ssh/known_hosts`

  The typical use case is allow fetching of git dependencies via ssh without causing an error.
  """
  use DockerBuild.Plugins

  @impl DockerBuild.Plugins
  def before_deps_get(df) do
    case plugin_config(df, :hosts) do
      hosts when is_list(hosts) ->
        df
        |> run("ssh-keyscan #{Enum.join(hosts, " ")} >> ~/.ssh/known_hosts")

      _ ->
        raise ArgumentError, message: "#{__MODULE__} must provide :hosts as list"
    end
  end
end
