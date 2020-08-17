# Changelog

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
