#!/bin/bash

set -e

export TAG=$1
export PROJECT=$2
export BASE_TAG=$3

if [ -z "$TAG" -o -z "$PROJECT" ]; then
  echo "Usage: ./build_gen_dockerfile.sh <tag> <project> [<basetag>]"
  echo "Please provide release tag and project name."
  exit 1
fi
if [ -z "$BASE_TAG" ]; then
  export BASE_TAG=$TAG
fi

cd build_steps
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$TAG|${TAG}|g" \
  < gen_dockerfile.yaml.in > gen_dockerfile.yaml
sed -e "s|\$BASE_TAG|${BASE_TAG}|g" \
  < gen_dockerfile/Dockerfile.in > gen_dockerfile/Dockerfile
gcloud alpha container builds create . --config=gen_dockerfile.yaml
