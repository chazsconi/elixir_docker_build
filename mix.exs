defmodule DockerBuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :docker_build,
      version: "0.1.0",
      elixir: ">= 1.6.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
