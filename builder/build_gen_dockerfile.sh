#!/bin/bash

set -e

export IMAGE=$1

if [ -z "$1" ]; then
  echo "Usage: ./build_gen_dockerfile.sh <image_path>"
  echo "Please provide fully qualified path to target image."
  exit 1
fi

cd build_steps
sed -e "s|\$IMAGE|${IMAGE}|g" < gen_dockerfile.yaml.in > gen_dockerfile.yaml
gcloud alpha container builds create . --config=gen_dockerfile.yaml
