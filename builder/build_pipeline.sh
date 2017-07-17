#!/bin/bash

set -e

DIRNAME=$(dirname $0)

BASE_IMAGE_TAG="latest"
IMAGE_TAG="new"
UPLOAD_BUCKET=

show_usage() {
  echo "Usage: ./build.sh [-i <base-image-tag>] [-t <image-tag>] [-b upload-bucket]" >&2
  echo "Flags:" >&2
  echo '  -i: set the base image tag (defaults to latest, or use "staging")' >&2
  echo '  -t: set the pipeline images tag (defaults to same as base image, or use "new")' >&2
  echo '  -b: set the gs bucket to upload to (omit to skip uploading)' >&2
}

OPTIND=1
while getopts ":i:t:b:h" opt; do
  case $opt in
    i)
      BASE_IMAGE_TAG=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    b)
      UPLOAD_BUCKET=$OPTARG
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

if [ -z "$BASE_IMAGE_TAG" -o -z "$IMAGE_TAG" ]; then
  echo "Usage: ./build_pipeline.sh <base_image_tag> <image_tag> [<bucket>]" >&2
  exit 1
fi

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

PROJECT=$(gcloud config get-value project)
if [ -z "$PROJECT" ]; then
  echo "Could not determine current project" >&2
  exit 1
fi

$DIRNAME/build_new.sh -i $BASE_IMAGE_TAG -t $IMAGE_TAG

mkdir -p $DIRNAME/pipeline
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$BUILDER_TAG|${IMAGE_TAG}|g" \
  < $DIRNAME/ruby-new.yaml.in > $DIRNAME/pipeline/ruby-$IMAGE_TAG.yaml
sed -e "s|\$BUILDER_TAG|${IMAGE_TAG}|g" \
  < $DIRNAME/runtimes.yaml.in > $DIRNAME/pipeline/runtimes.yaml
echo -n $IMAGE_TAG > $DIRNAME/pipeline/ruby.version

if [ -n "$UPLOAD_BUCKET" ]; then
  gsutil cp $DIRNAME/pipeline/ruby-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/ruby-$IMAGE_TAG.yaml
  gsutil cp $DIRNAME/pipeline/runtimes.yaml gs://$UPLOAD_BUCKET/runtimes.yaml
  gsutil cp $DIRNAME/pipeline/ruby.version gs://$UPLOAD_BUCKET/ruby.version
fi
