#!/bin/sh
set -e

BUILD_ENV=${1-dev}
is_local() {
  if [ "$BUILD_ENV" = "prod" ]; then
    return 1
  else
    return 0
  fi
}

# Make sure correct versions are installed, and if not, attempt to install them
# using asdf
. ./bin/check_tool_versions.sh

# Sometimes cached builds will have conflicts when bumping deps versions, so
# you can always run this script to make the build pure again.
if is_local; then
  echo "Removing previous build artifacts"
  rm -rf deps _build
fi

echo "Installing dependencies and compiling"
mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile

. ./bin/setup_assets.sh

# This is for developer's local setup of the project. Not for the release
# process. This way any developer setting up the project locally can run
# bin/setup and then mix phx.server to get running quickly
if is_local; then
  echo "Setting up database"
  mix ecto.reset
  MIX_ENV="test" mix ecto.reset
  mix run priv/repo/seeds.exs

  PROJECT_ROOT=$(pwd)
  cd assets
  echo "Compiling assets"
  node_modules/brunch/bin/brunch build
  cd "$PROJECT_ROOT"
fi
