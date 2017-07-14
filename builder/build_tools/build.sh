#!/bin/bash

set -e

DIRNAME=$(dirname $0)

IMAGE_TAG="new"
STAGING_FLAG=

show_usage() {
  echo "Usage: ./build.sh [-t <image-tag>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -t: set the image tag (defaults to "new")' >&2
  echo '  -s: also tag new image as staging' >&2
}

OPTIND=1
while getopts ":t:sh" opt; do
  case $opt in
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

if [ "$IMAGE_TAG" = "new" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi

EXISTING=$(gcloud container images list-tags gcr.io/$PROJECT/ruby/build-tools --filter=tags=$IMAGE_TAG --format='get(tags)')
if [ -n "$EXISTING" ]; then
  echo "Tag $IMAGE_TAG for gcr.io/$PROJECT/ruby/build-tools already exists. Aborting." >&2
  exit 1
fi

pushd $DIRNAME
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$IMAGE_TAG|${IMAGE_TAG}|g" \
  < cloudbuild.yaml.in > cloudbuild.yaml
cp Dockerfile.in Dockerfile
gcloud container builds submit . --config=cloudbuild.yaml
popd

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag \
    gcr.io/$PROJECT/ruby/build-tools:$IMAGE_TAG \
    gcr.io/$PROJECT/ruby/build-tools:staging -q
fi
