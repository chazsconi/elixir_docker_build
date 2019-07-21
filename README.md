# K8SDeploy

Library for building and deploying Phoenix applications to Kubernetes

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `k8s_deploy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:k8s_deploy, "~> 0.1.0", only: :dev}
  ]
end
```

You also need to add distillery to your project.  Normally this is done with:

```elixir
def deps do
  [
    {:distillery, "~> 2.1"},
  ]
end
```

Then run `mix distillery.init` to create an initially distillery configuration file.

## Basic Use

### Add configuration

Create the following entries in `config/dev.exs`.  As you will run the `mix` tasks in the
development environment you should only add them here.

```elixir
# config/dev.exs
config :k8s_deploy, K8SDeploy.Build,
  app_name: :my_project,
  docker_image: "docker.registry.url/my_project:production"
```

### Build docker image

To build a release docker image:

```bash
mix k8s.build
```

The task generates a `.dockerignore` file in the root of the project so you will probably
want to add this to `.gitignore`.

### Run docker image
The build image can be run with
```bash
docker run docker.registry.url/my_project:production
```
However, this will probably fail if your project relies on environment variables at runtime.
