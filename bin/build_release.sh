#!/bin/bash
set -e

# This assumes Phoenix 1.3 structure with assets in ./assets
PROJECT_ROOT=$(pwd)
cd assets
./node_modules/brunch/bin/brunch build --production
cd "$PROJECT_ROOT"

mix phoenix.digest
mix release --env prod --verbose
