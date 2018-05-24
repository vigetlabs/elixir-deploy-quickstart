#!/bin/sh
set -e

echo "Installing NPM dependencies"
PROJECT_ROOT=$(pwd)
cd assets
npm install --progress=false
cd "$PROJECT_ROOT"
