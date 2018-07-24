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

PROJECT=
IMAGE_NAME="exec-wrapper"
IMAGE_TAG=
STAGING_FLAG=
AUTO_YES=

show_usage() {
  echo "Usage: ./build-app-engine-exec-wrapper.sh [flags...]" >&2
  echo "Flags:" >&2
  echo '  -n <name>: set the image name (defaults to `exec-wrapper`)' >&2
  echo '  -p <project>: set the project (defaults to current gcloud config)' >&2
  echo '  -s: tag new image as staging' >&2
  echo '  -t <tag>: set the new image tag (defaults to a new tag)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":n:p:st:yh" opt; do
  case ${opt} in
    n)
      IMAGE_NAME=${OPTARG}
      ;;
    p)
      PROJECT=${OPTARG}
      ;;
    s)
      STAGING_FLAG="true"
      ;;
    t)
      IMAGE_TAG=${OPTARG}
      ;;
    y)
      AUTO_YES="true"
      ;;
    h)
      show_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      echo >&2
      show_usage
      exit 1
      ;;
    :)
      echo "Option ${OPTARG} requires a parameter" >&2
      echo >&2
      show_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${PROJECT}" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using project from gcloud config: ${PROJECT}" >&2
fi
if [ -z "${IMAGE_TAG}" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: ${IMAGE_TAG}" >&2
fi

EXISTING=$(gcloud container images list-tags gcr.io/${PROJECT}/${IMAGE_NAME} --filter=tags=${IMAGE_TAG} --format='get(tags)')
if [ -n "${EXISTING}" ]; then
  echo "Tag ${IMAGE_TAG} for gcr.io/${PROJECT}/${IMAGE_NAME} already exists. Aborting." >&2
  exit 1
fi

echo
echo "Building appengine exec wrapper image:"
echo "  gcr.io/${PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  echo "and tagging as staging."
else
  echo "but NOT tagging as staging."
fi
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi
echo

gcloud builds submit ${DIRNAME}/app-engine-exec-wrapper \
  --config=${DIRNAME}/app-engine-exec-wrapper/cloudbuild.yaml --project ${PROJECT} \
  --substitutions _OUTPUT_IMAGE=gcr.io/${PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
echo "**** Built image: gcr.io/${PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    gcr.io/${PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} \
    gcr.io/${PROJECT}/${IMAGE_NAME}:staging -q
  echo "**** Tagged image as gcr.io/${PROJECT}/${IMAGE_NAME}:staging"
fi
