# K8SDeploy

Library for building and deploying Phoenix applications to Kubernetes

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `k8s_deploy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:k8s_deploy, "~> 0.1.0", runtime: false, only: :dev}
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
development environment you should only add them here.  This assumes that
you are using webpack to compile assets.

```elixir
# config/dev.exs
config :k8s_deploy, K8SDeploy.Build,
  plugins: [K8SDeploy.Plugins.Webpack],
  app_name: :my_project,
  elixir_version: "1.8.1",
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

## Advanced usage

### Additional configuration

The following additional config values are available:

  * `:assets_path` - path the assets within your project. Defaults to `assets`.
  * `:umbrella_apps` - list of apps in an umbrella project.  If not set then the project is
  assumed to be a non-umbrella project.

## Plugin System

A plugin system is available to extend the dockerfile that is generated via various callbacks.

In the config a list of plugins can be given.  Each item can either be the module name (if no
configuration is required), or a tuple of the plugin and a keyword list of config values to provide
a list of config values to the plugin:

```elixir
# config/dev.exs
config :k8s_deploy, K8SDeploy.Build,
  plugins: [PluginModule1, {PluginModule2, foo1: :bar1, foo2: :bar2}`, PluginModule3],
  ...
```

If complex config is required the plugin can just be listed with its module name in the
`:plugins` config key and separate config can be given for the module:

```elixir
# config/dev.exs
config :k8s_deploy, K8SDeploy.Build,
  plugins: [PluginModule1, PluginModule2, PluginModule3],
  ...

config :k8s_deploy, PluginModule2,
  foo1: :bar1,
  foo2: :bar2
```

There are several plugins already included in the project.

## Troubleshooting

### The webserver does not start

Ensure that you have set `server: true` in you endpoint:

```elixir
# config/prod.exs
config :my_app, MyApp.Endpoint,
  server: true
```

## Design Decisions

### Selection of environment

The environment to build under (i.e. what `MIX_ENV` is set to in Docker) is set from the command line.  This has the following advantage over taking the current value of `MIX_ENV` when invoking the task:

1. When building a `prod` release the project and dependencies do not need to be compiled locally with `MIX_ENV=prod` just to run the mix task.

2. The configuration for the build can be placed in `config/dev.exs` and so will not be included in `sys.config` when the release is built by Distillery.  You may have secrets in here you do not want in your final docker image.
