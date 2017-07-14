#!/bin/bash

set -e

DIRNAME=$(dirname $0)

BASE_IMAGE_TAG="latest"
BUILD_TOOLS_TAG="latest"
IMAGE_TAG="new"
STAGING_FLAG=

show_usage() {
  echo "Usage: ./build.sh [-i <base-image-tag>] [-j <build-tools-tag>] [-t <image-tag>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -i: set the base image tag (defaults to latest, or use "staging")' >&2
  echo '  -j: set the build tools tag (defaults to latest, or use "staging")' >&2
  echo '  -t: set the builder tag (defaults to same as base image, or use "new")' >&2
  echo '  -s: also tag new image as staging' >&2
}

OPTIND=1
while getopts ":i:j:t:sh" opt; do
  case $opt in
    i)
      BASE_IMAGE_TAG=$OPTARG
      ;;
    j)
      BUILD_TOOLS_TAG=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    s)
      STAGING_FLAG="true"
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

PROJECT=$(gcloud config get-value project)
if [ -n "$PROJECT" ]; then
  echo "Building to project ${PROJECT}" >&2
else
  echo "Could not determine current project" >&2
  exit 1
fi

if [ "$BASE_IMAGE_TAG" = "staging" -o "$BASE_IMAGE_TAG" = "latest" ]; then
  SYMBOL=$BASE_IMAGE_TAG
  BASE_IMAGE_TAG=$(gcloud container images list-tags gcr.io/google-appengine/ruby --filter=tags=$BASE_IMAGE_TAG --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting BASE_IMAGE_TAG to ${SYMBOL}: $BASE_IMAGE_TAG" >&2
fi

if [ "$BUILD_TOOLS_TAG" = "staging" -o "$BUILD_TOOLS_TAG" = "latest" ]; then
  SYMBOL=$BUILD_TOOLS_TAG
  BUILD_TOOLS_TAG=$(gcloud container images list-tags gcr.io/$PROJECT/ruby/build-tools --filter=tags=$BUILD_TOOLS_TAG --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting BUILD_TOOLS_TAG to ${SYMBOL}: $BUILD_TOOLS_TAG" >&2
fi

if [ "$IMAGE_TAG" = "new" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi
if [ "$IMAGE_TAG" = "same" ]; then
  IMAGE_TAG=$BASE_IMAGE_TAG
  echo "Setting IMAGE_TAG to $IMAGE_TAG (same as base image tag)" >&2
fi

EXISTING=$(gcloud container images list-tags gcr.io/$PROJECT/ruby/generate-dockerfile --filter=tags=$IMAGE_TAG --format='get(tags)')
if [ -n "$EXISTING" ]; then
  echo "Tag $IMAGE_TAG for gcr.io/$PROJECT/ruby/generate-dockerfile already exists. Aborting." >&2
  exit 1
fi

pushd $DIRNAME
BASE_IMAGE="gcr.io/google-appengine/ruby:${BASE_IMAGE_TAG}"
BUILD_TOOLS_IMAGE="gcr.io/${PROJECT}/ruby/build-tools:${BUILD_TOOLS_TAG}"
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$IMAGE_TAG|${IMAGE_TAG}|g" \
  < cloudbuild.yaml.in > cloudbuild.yaml
sed -e "s|\$BASE_IMAGE|${BASE_IMAGE}|g; s|\$BUILD_TOOLS_IMAGE|${BUILD_TOOLS_IMAGE}|g" \
  < Dockerfile.in > Dockerfile
gcloud container builds submit . --config=cloudbuild.yaml
popd

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag \
    gcr.io/$PROJECT/ruby/generate-dockerfile:$IMAGE_TAG \
    gcr.io/$PROJECT/ruby/generate-dockerfile:staging -q
fi
