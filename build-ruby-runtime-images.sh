#!/bin/bash

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

DIRNAME=$(dirname $0)

RUNTIME_NAME=ruby
BASE_PROJECT=
BUILDER_PROJECT=
IMAGE_TAG=
STAGING_FLAG=
AUTO_YES=

show_usage() {
  echo 'Usage: build-ruby-runtime-images.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -p <project>: set the base image project (defaults to current gcloud config setting)' >&2
  echo '  -q <project>: set the builder images project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":n:p:q:st:yh" opt; do
  case $opt in
    n)
      RUNTIME_NAME=$OPTARG
      ;;
    p)
      BASE_PROJECT=$OPTARG
      ;;
    q)
      BUILDER_PROJECT=$OPTARG
      ;;
    s)
      STAGING_FLAG="true"
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    y)
      AUTO_YES="true"
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

if [ -z "$BASE_PROJECT" ]; then
  BASE_PROJECT=$(gcloud config get-value project)
  echo "Using base image project from gcloud config: $BASE_PROJECT" >&2
fi
if [ -z "$BUILDER_PROJECT" ]; then
  BUILDER_PROJECT=$(gcloud config get-value project)
  echo "Using builder image project from gcloud config: $BUILDER_PROJECT" >&2
fi
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi

echo
echo "Building base, tools, and dockerfile generator images:"
echo "  gcr.io/$BASE_PROJECT/$RUNTIME_NAME:$IMAGE_TAG"
echo "  gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/build-tools:$IMAGE_TAG"
echo "  gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
fi
if [ -z "$AUTO_YES" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "$response" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

echo
gcloud container builds submit $DIRNAME/ruby-base \
  --config $DIRNAME/ruby-base/cloudbuild.yaml --project $BASE_PROJECT \
  --substitutions _TAG=$IMAGE_TAG
echo "**** Built image: gcr.io/$BASE_PROJECT/$RUNTIME_NAME:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $BASE_PROJECT \
    gcr.io/$BASE_PROJECT/$RUNTIME_NAME:$IMAGE_TAG \
    gcr.io/$BASE_PROJECT/$RUNTIME_NAME:staging -q
  echo "**** And tagged as gcr.io/$BASE_PROJECT/$RUNTIME_NAME:staging"
fi

gcloud container builds submit $DIRNAME/ruby-build-tools \
  --config $DIRNAME/ruby-build-tools/cloudbuild.yaml --project $BUILDER_PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_BASE_PROJECT_ID=$BASE_PROJECT
echo "**** Built image: gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/build-tools:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $BUILDER_PROJECT \
    gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/build-tools:$IMAGE_TAG \
    gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/build-tools:staging -q
  echo "**** And tagged as gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/build-tools:staging"
fi

gcloud container builds submit $DIRNAME/ruby-generate-dockerfile \
  --config $DIRNAME/ruby-generate-dockerfile/cloudbuild.yaml --project $BUILDER_PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_BASE_PROJECT_ID=$BASE_PROJECT
echo "**** Built image: gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $BUILDER_PROJECT \
    gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:$IMAGE_TAG \
    gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:staging -q
  echo "**** And tagged as gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:staging"
fi
