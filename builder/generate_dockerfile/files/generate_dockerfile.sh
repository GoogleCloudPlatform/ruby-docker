#!/bin/bash

set -e

WORKSPACE_DIR=$(/bin/pwd)
cd /app
ruby generate_dockerfile.rb --workspace-dir=${WORKSPACE_DIR} "$@"
