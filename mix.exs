defmodule DockerBuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :docker_build,
      version: "0.3.2",
      elixir: ">= 1.6.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "DockerBuild",
      source_url: "https://github.com/chazsconi/elixir_docker_build",
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

  defp description do
    """
    Library for building docker images of Elixir projects.  Supports a plugin
    system which can allows the generated Dockerfile to be extended at various
    points.
    """
  end

  defp package do
    [
      name: :docker_build,
      maintainers: ["Charles Bernasconi"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/chazsconi/elixir_docker_build"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
