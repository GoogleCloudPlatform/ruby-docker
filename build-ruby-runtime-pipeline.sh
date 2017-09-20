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

UPLOAD_BUCKET=
RUNTIME_NAME=ruby
BUILDER_PROJECT=
RUNTIME_VERSION=
IMAGE_TAG=
STAGING_FLAG=
AUTO_YES=

show_usage() {
  echo 'Usage: build-ruby-runtime-pipeline.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -b <bucket>: upload a new runtime definition to this gcs bucket (required)' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -q <project>: set the builder images project (defaults to current gcloud config setting)' >&2
  echo '  -r <version>: set the runtime release (defaults to create a new version)' >&2
  echo '  -s: also upload a staging runtime pipeline (defaults to false)' >&2
  echo '  -t <tag>: use the given image tag (defaults to latest)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":b:n:q:r:st:yh" opt; do
  case $opt in
    b)
      UPLOAD_BUCKET=$OPTARG
      ;;
    n)
      RUNTIME_NAME=$OPTARG
      ;;
    q)
      BUILDER_PROJECT=$OPTARG
      ;;
    r)
      RUNTIME_VERSION=$OPTARG
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

if [ -z "$UPLOAD_BUCKET" ]; then
  echo "Error: -b flag is required." >&2
  echo >&2
  show_usage
  exit 1
fi

if [ -z "$BUILDER_PROJECT" ]; then
  BUILDER_PROJECT=$(gcloud config get-value project)
  echo "Using builder image project from gcloud config: $BUILDER_PROJECT" >&2
fi

if [ -z "$RUNTIME_VERSION" ]; then
  RUNTIME_VERSION=$(date +%Y%m%d%H%M%S)
  echo "Creating new RUNTIME_VERSION: $RUNTIME_VERSION" >&2
fi

if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=latest
fi
if [ "$IMAGE_TAG" = "staging" -o "$IMAGE_TAG" = "latest" ]; then
  SYMBOL=$IMAGE_TAG
  IMAGE_TAG=$(gcloud container images list-tags gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile --filter=tags=$SYMBOL --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting IMAGE_TAG to ${SYMBOL}: $IMAGE_TAG" >&2
fi

echo
echo "Creating and uploading a new runtime config:"
echo "  gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-$RUNTIME_VERSION.yaml"
if [ "$STAGING_FLAG" = "true" ]; then
  echo "  gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-staging.yaml"
else
  echo "but NOT uploading it as staging."
fi
echo "It references gcr.io/$BUILDER_PROJECT/$RUNTIME_NAME/generate-dockerfile:$IMAGE_TAG"
if [ -z "$AUTO_YES" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "$response" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

echo
mkdir -p $DIRNAME/tmp
sed -e "s|\$PROJECT|${BUILDER_PROJECT}|g; s|\$TAG|${IMAGE_TAG}|g" \
  < $DIRNAME/ruby-pipeline/ruby-template.yaml.in > $DIRNAME/tmp/ruby-$RUNTIME_VERSION.yaml
gsutil cp $DIRNAME/tmp/ruby-$RUNTIME_VERSION.yaml gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-$RUNTIME_VERSION.yaml
echo "**** Uploaded runtime config to gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-$RUNTIME_VERSION.yaml"
if [ "$STAGING_FLAG" = "true" ]; then
  gsutil cp gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-$RUNTIME_VERSION.yaml gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-staging.yaml
  echo "**** Also promoted runtime config to gs://$UPLOAD_BUCKET/$RUNTIME_NAME-default-builder-staging.yaml"
fi
