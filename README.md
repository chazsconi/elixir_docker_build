# DockerBuild

Library for building docker images.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `docker_build` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:docker_build, "~> 0.1.0", runtime: false, only: :dev}
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
config :docker_build, DockerBuild.Build,
  plugins: [DockerBuild.Plugins.Webpack],
  app_name: :my_project,
  elixir_version: "1.8.1",
  docker_image: "docker.registry.url/my_project:production"
```

### Build docker image

To build a release docker image:

```bash
mix docker.build
```

The task generates a `.dockerignore` file in the root of the project so you will probably
want to add this to `.gitignore`.

A two-stage build is used so the final docker image will not contain source code.

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
  * `:extra_dockerignore` - a list of paths to add to the generated `.dockerignore` files. By
  default all files are excluded so it is likely you will want to use this to explicitly
  include files by prefixing them with `!`.
  * `:umbrella_apps` - list of apps in an umbrella project.  If not set then the project is
  assumed to be a non-umbrella project.

### Adding ssh keys to the build stage

You can add these in `deploy/ssh_keys`.  Typically you would add a private and public key, e.g.
`id_rsa` and `id_rsa.pub`.  They will be copied to the `/root/.ssh` folder in the build
stage docker image.

The typical use case for this is a deployment key to fetch some dependencies from a private
git repo.  In this case you may also need to use the `DockerBuild.Plugins.KnownHosts` plugin
to add the host of the source repo.

For example for a dependency that is in a private Github repo:

1. Generate a new key pair:
```
mkdir -p deploy/ssh_keys
ssh-keygen -f deploy/ssh_keys/id_rsa -N "" -C my_project-docker-build
```

2. Go to the deployment keys section for your dependency
in Github's UI (*Settings -> Deploy keys*) and add a new key with the
contents of `id_rsa.pub`.

3. Add `github.com` to the `KnownHosts` plugin.
```
plugins: [
  {DockerBuild.Plugins.KnownHosts, hosts: ["github.com"]}
]
```

## Plugin System

A plugin system is available to extend the dockerfile that is generated via various callbacks.

In the config a list of plugins can be given.  Each item can either be the module name (if no
configuration is required), or a tuple of the plugin and a keyword list of config values to provide
a list of config values to the plugin:

```elixir
# config/dev.exs
config :docker_build, DockerBuild.Build,
  plugins: [PluginModule1, {PluginModule2, foo1: :bar1, foo2: :bar2}`, PluginModule3],
  ...
```

If complex config is required the plugin can just be listed with its module name in the
`:plugins` config key and separate config can be given for the module:

```elixir
# config/dev.exs
config :docker_build, DockerBuild.Build,
  plugins: [PluginModule1, PluginModule2, PluginModule3],
  ...

config :docker_build, PluginModule2,
  foo1: :bar1,
  foo2: :bar2
```

There are several plugins already included in the project.

## Troubleshooting

### Host key verification failed error

If you see this when fetching dependencies, ensure that you have the source repo
added to `DockerBuild.Plugins.KnownHosts` plugin.

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

## TODO

### Check mandatory config params

Currently a protocol error is shown if the config is missing.

### Optional Assets

Either:
  * Add assets as a plugin, and have some plugin hierarchy, deps resolution or be able to set
  plugin config options from another plugin - e.g. `assets_compile_command:` from webpack/brunch plugin.
  * Make `assets_path:` config option mandatory so this can be used for apps without assets.

### Extract SSH Keys copy to plugin
