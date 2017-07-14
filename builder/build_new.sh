#!/bin/bash

set -e

DIRNAME=$(dirname $0)

BASE_IMAGE_TAG="latest"
IMAGE_TAG="new"
STAGING_FLAG=

show_usage() {
  echo "Usage: ./build.sh [-i <base-image-tag>] [-t <image-tag>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -i: set the base image tag (defaults to latest, or use "staging")' >&2
  echo '  -t: set the pipeline images tag (defaults to same as base image, or use "new")' >&2
  echo '  -s: also tag new images as staging' >&2
}

OPTIND=1
while getopts ":i:t:sh" opt; do
  case $opt in
    i)
      BASE_IMAGE_TAG=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    s)
      STAGING_FLAG="-s"
      ;;
    h)
      show_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo >&2
      show_usage
      exit 1
      ;;
    :)
      echo "Option $OPTARG requires a parameter" >&2
      echo >&2
      show_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ "$BASE_IMAGE_TAG" = "staging" -o "$BASE_IMAGE_TAG" = "latest" ]; then
  SYMBOL=$BASE_IMAGE_TAG
  BASE_IMAGE_TAG=$(gcloud container images list-tags gcr.io/google-appengine/ruby --filter=tags=$BASE_IMAGE_TAG --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting BASE_IMAGE_TAG to ${SYMBOL}: $BASE_IMAGE_TAG" >&2
fi

if [ "$IMAGE_TAG" = "new" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi
if [ "$IMAGE_TAG" = "same" ]; then
  IMAGE_TAG=$BASE_IMAGE_TAG
  echo "Setting IMAGE_TAG to $IMAGE_TAG (same as base image tag)" >&2
fi

$DIRNAME/build_tools/build.sh -t $IMAGE_TAG $STAGING_FLAG
$DIRNAME/generate_dockerfile/build.sh -i $BASE_IMAGE_TAG -j $IMAGE_TAG -t $IMAGE_TAG $STAGING_FLAG
