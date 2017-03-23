#!/bin/bash

set -e

DIRNAME=$(dirname $0)

STEP=$1

BASE_IMAGE_TAG="latest"
BUILDER_TAG="same"
STAGING_FLAG=

show_usage() {
  echo "Usage: ./build.sh <step> [-i <base-image-tag>] [-t <builder-tag>] [-s]" >&2
  echo '<step> can be either "build_app" or "gen_dockerfile"'
  echo "Flags:" >&2
  echo '  -i: set the base image tag (defaults to latest, or use "staging")' >&2
  echo '  -t: set the builder tag (defaults to same as base image, or use "new")' >&2
  echo '  -s: tag new build step as staging' >&2
}

OPTIND=2
while getopts ":i:t:sh" opt; do
  case $opt in
    i)
      BASE_IMAGE_TAG=$OPTARG
      ;;
    t)
      BUILDER_TAG=$OPTARG
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
STEP_NAME=$(echo "$STEP" | sed 's|_|-|g')

PROJECT=$(gcloud config get-value project)
if [ -z "$PROJECT" ]; then
  echo "Could not determine current project" >&2
  exit 1
fi

EXISTING=$(gcloud beta container images list-tags gcr.io/$PROJECT/ruby/$STEP_NAME --filter=tags=$BUILDER_TAG --format='get(tags)')
if [ -n "$EXISTING" ]; then
  echo "Tag $BUILDER_TAG for $STEP_NAME in project $PROJECT already exists. Aborting." >&2
  exit 1
fi

pushd $DIRNAME/build_steps
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$BUILDER_TAG|${BUILDER_TAG}|g" \
  < $STEP.yaml.in > $STEP.yaml
sed -e "s|\$BASE_IMAGE_TAG|${BASE_IMAGE_TAG}|g" \
  < $STEP/Dockerfile.in > $STEP/Dockerfile
gcloud beta container builds submit . --config=$STEP.yaml
popd

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud beta container images add-tag \
    gcr.io/$PROJECT/ruby/$STEP_NAME:$BUILDER_TAG \
    gcr.io/$PROJECT/ruby/$STEP_NAME:staging -q
fi
