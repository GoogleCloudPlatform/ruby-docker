#!/bin/bash

set -e

export IMAGE=$1

if [ -z "$1" ]; then
  echo "Usage: ./build_build_app.sh <image_path>"
  echo "Please provide fully qualified path to target image."
  exit 1
fi

cd build_steps
sed -e "s|\$IMAGE|${IMAGE}|g" < build_app.yaml.in > build_app.yaml
gcloud alpha container builds create . --config=build_app.yaml
