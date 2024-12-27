# Changelog

## v0.11.0

### Enhancements
* Add `:build_stage_base_image` param

### Other
* Install `git`, `make`, `gcc` in base image in case it is not there as it is requried by some
  elixir libraries.

## v0.10.0

### Enhancements
* Add `COMMIT_SHA` Docker ARG that sets corresponding environment variable.

## v0.9.0

### Enhancements
* Add support for base images that use Debian bookworm

## v0.8.0

### Enhancements
* Add `--no-build` and `--target` command line options
* `Assets` plugin - Support node v20
* `Assets` plugin - Change node installation method to use package repository rather than deprecated curl script

### Bug fixes
* Change `Logger.warn` to `Logger.warning` as caused compile warning.

### Breaking changes
* Set min elixir version to 1.11.  This is required due to the `Logger.warning` change.
* `Assets` plugin - Remove versions below v16 is required as the new installation method
  is only supported for >= v16.
* `Webpack` plugin - Remove `--optimize-minimize` flag longer required for >= v4.
* `Webpack` plugin - remove support for < v4.  It may still work but the assets will not be optimized due to
  the flag being

### v0.7.0
* Added `before_compile` and `install_runtime_deps` callback.  These can be used extra build or runtime
  linux packages are required.

## v0.6.0

### Enhancements
* Support custom plugins in own project
* Add `before_assets_compile` callback in Assets plugin

## v0.5.1

### Bug fixes
* Added `ca-certificates` package to release stage - this could have cause problems if using packages relying on the certificates to be installed

### Other
* Removed references to Elixir <= v1.9 defaulting to distillery

## v0.5.0

### Enhancements
* `Assets` are extracted into a separate plugin and allows the NodeJS version to be configured.  This defaults to v16.
See [README.md](README.md) and below for details.

### Breaking changes
* With the `Assets` plugin extraction the default Nodejs version has been changed from v12 to v16.  However, this can
be now be set explicity to an older version.  See the `Assets` plugin for details.
* The `assets_path` configuration is now within the `Assets` plugin and needs to be moved here if you do not use the default value of `assets`.

### Removed
* Brunch plugin
* Support for Elixir < 1.9

## v0.4.0
### Breaking changes
* The configuration is now in the `docker_build:` entry in the `project/0` within `mix.exs` instead of in `dev.exs`.
See [README.md](README.md) for details.

## v0.3.4

* Bug fixes
  * Do not specify a specific version of npm to install as this fails when
  package is no longer available

## v0.3.3

* Bug fixes
  * Use npm 10.22.0 as 10.20.0 no longer available

## v0.3.2

* Bug fixes
  * Release base image depends on Elixir version.  Previously Elixir 1.9 could fail
  on boot due to missing runtime libraries.

## v0.3.1

* Updates
  * Use npm 10 as npm 8 is deprecated and causes a 20s delay on install

## v0.3.0

* Enhancements
  * Support for Elixir 1.9 built-in releases

* Bug fixes
  * Ensure correct npm version is installed

## v0.2.0

* Enhancements
  * Allow adding curl .netrc file

* Bug fixes
  * Create .ssh folder for KnownHosts plugin if it doesn't exist


## v0.1.2

* Bug fixes
  * Add priv/static to .dockerignore for umbrella apps

## v0.1.1

* Bug fixes
  * Exit code 1 if build fails

* Other
  * Enhance README with examples of ssh keys and known hosts

## v0.1.0

* First release
