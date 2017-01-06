#!/bin/bash

set -e

export TAG=$1
export PROJECT=$2
export BASE_TAG=$3

if [ -z "$TAG" -o -z "$PROJECT" ]; then
  echo "Usage: ./build_build_app.sh <tag> <project> [<basetag>]"
  echo "Please provide release tag and project name."
  exit 1
fi
if [ -z "$BASE_TAG" ]; then
  export BASE_TAG=$TAG
fi

cd build_steps
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$TAG|${TAG}|g" \
  < build_app.yaml.in > build_app.yaml
sed -e "s|\$BASE_TAG|${BASE_TAG}|g" \
  < build_app/Dockerfile.in > build_app/Dockerfile
gcloud alpha container builds create . --config=build_app.yaml
