defmodule Mix.Tasks.K8s.Build do
  use Mix.Task
  alias K8SDeploy.Build

  @shortdoc "Builds a docker image for the project"

  @moduledoc """
  Builds a new docker image for the project

  ## Example

  mix k8s_deploy.build
  """

  def run(_args) do
    dockerfile = Build.run()
    Mix.shell().info(to_string(dockerfile))
  end
end
