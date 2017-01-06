#!/bin/bash

set -e

export TAG=$1
export PROJECT=$2

if [ -z "$TAG" -o -z "$PROJECT" ]; then
  echo "Usage: ./build.sh <tag> <project>"
  echo "Please provide release tag and project name."
  exit 1
fi

./build_gen_dockerfile.sh $TAG $PROJECT
./build_build_app.sh $TAG $PROJECT
./build_pipeline.sh $TAG $PROJECT
