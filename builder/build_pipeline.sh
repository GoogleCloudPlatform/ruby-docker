#!/bin/bash

set -e

DIRNAME=$(dirname $0)

BASE_IMAGE_TAG=$1
BUILDER_TAG=$2

if [ -z "$BASE_IMAGE_TAG" -o -z "$BUILDER_TAG" ]; then
  echo "Usage: ./build_pipeline.sh <base_image_tag> <builder_tag>" >&2
  exit 1
fi

if [ "$BASE_IMAGE_TAG" = "staging" -o "$BASE_IMAGE_TAG" = "latest" ]; then
  SYMBOL=$BASE_IMAGE_TAG
  BASE_IMAGE_TAG=$(gcloud beta container images list-tags gcr.io/google-appengine/ruby --filter=tags=$BASE_IMAGE_TAG --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting BASE_IMAGE_TAG to ${SYMBOL}: $BASE_IMAGE_TAG" >&2
fi
if [ "$BUILDER_TAG" = "new" ]; then
  BUILDER_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new BUILDER_TAG: $BUILDER_TAG" >&2
fi
if [ "$BUILDER_TAG" = "same" ]; then
  BUILDER_TAG=$BASE_IMAGE_TAG
  echo "Setting BUILDER_TAG to $BUILDER_TAG (same as base image tag)" >&2
fi

PROJECT=$(gcloud config get-value project)
if [ -z "$PROJECT" ]; then
  echo "Could not determine current project" >&2
  exit 1
fi

$DIRNAME/build.sh -i $BASE_IMAGE_TAG -t $BUILDER_TAG

mkdir -p $DIRNAME/pipeline
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$BUILDER_TAG|${BUILDER_TAG}|g; s|\$BASE_IMAGE_TAG|${BASE_IMAGE_TAG}|g" \
  < $DIRNAME/ruby.yaml.in > $DIRNAME/pipeline/ruby-$BUILDER_TAG.yaml
echo -n $BUILDER_TAG > $DIRNAME/pipeline/ruby.version
