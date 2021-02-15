#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" || exit ; pwd -P )"

gem install yard

cd "${SCRIPT_PATH}"/.. || exit

rm -rf "${SCRIPT_PATH}"/docs
yard -o docs 'lib/**/*.rb' 'apis/lib/**/*.rb' - README LICENSE CHANGELOG.md