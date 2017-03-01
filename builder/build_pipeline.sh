#!/bin/bash

set -e

export TAG=$1
export PROJECT=$2

if [ -z "$TAG" -o -z "$PROJECT" ]; then
  echo "Usage: ./build_pipeline.sh <tag> <project>"
  echo "Please provide release tag and project name."
  exit 1
fi

mkdir -p pipeline
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$TAG|${TAG}|g" \
  < ruby.yaml.in > pipeline/ruby-$TAG.yaml
echo -n $TAG > pipeline/ruby.version
