defmodule K8SDeploy.Plugins.KnownHosts do
  use K8SDeploy.Plugins

  @impl K8SDeploy.Plugins
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
