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

OS_NAME=ubuntu16
RUNTIME_NAME=ruby
PROJECT=
IMAGE_TAG=
BASE_IMAGE_TAG=staging
STAGING_FLAG=
AUTO_YES=
PREBUILT_VERSIONS=()

if [ -f ${DIRNAME}/prebuilt-versions.txt ]; then
  mapfile -t PREBUILT_VERSIONS < ${DIRNAME}/prebuilt-versions.txt
fi

show_usage() {
  echo 'Usage: build-ruby-binary-images.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -a <tag>: use this base image tag (defaults to `staging`)' >&2
  echo '  -c <versions>: comma separated prebuilt ruby versions (defaults to prebuilt-versions.txt)' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to ubuntu16)' >&2
  echo '  -p <project>: set the project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":a:c:n:o:p:st:yh" opt; do
  case ${opt} in
    a)
      BASE_IMAGE_TAG=${OPTARG}
      ;;
    c)
      if [ "${OPTARG}" = "none" ]; then
        PREBUILT_VERSIONS=()
      else
        IFS=',' read -r -a PREBUILT_VERSIONS <<< "${OPTARG}"
      fi
      ;;
    n)
      RUNTIME_NAME=${OPTARG}
      ;;
    o)
      OS_NAME=${OPTARG}
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

if [ "${#PREBUILT_VERSIONS[@]}" = "0" ]; then
  echo "No versions to build. Aborting."
  exit 1
fi

if [ -z "${PROJECT}" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using project from gcloud config: ${PROJECT}" >&2
fi
if [ -z "${IMAGE_TAG}" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: ${IMAGE_TAG}" >&2
fi

OS_BASE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}
PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/prebuilt/ruby-

echo
echo "Using ${OS_BASE_IMAGE}:${BASE_IMAGE_TAG}"
echo "Building images:"
for version in "${PREBUILT_VERSIONS[@]}"; do
  echo "  ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG}"
done
if [ "${STAGING_FLAG}" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
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

sed -e "s|@@RUBY_OS_IMAGE@@|ruby-${OS_NAME}|g" \
  < ${DIRNAME}/ruby-prebuilt/Dockerfile.in > ${DIRNAME}/ruby-prebuilt/Dockerfile
for version in "${PREBUILT_VERSIONS[@]}"; do
  gcloud builds submit ${DIRNAME}/ruby-prebuilt \
    --config ${DIRNAME}/ruby-prebuilt/cloudbuild.yaml --project ${PROJECT} --timeout 20m \
    --substitutions _OS_NAME=${OS_NAME},_OS_BASE_IMAGE=${OS_BASE_IMAGE},_IMAGE=${PREBUILT_IMAGE_PREFIX}${version},_TAG=${IMAGE_TAG},_BASE_TAG=${BASE_IMAGE_TAG},_RUBY_VERSION=${version}
  echo "**** Built image: ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG}"
  if [ "${STAGING_FLAG}" = "true" ]; then
    gcloud container images add-tag --project ${PROJECT} \
      ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG} \
      ${PREBUILT_IMAGE_PREFIX}${version}:staging -q
    echo "**** And tagged as ${PREBUILT_IMAGE_PREFIX}${version}:staging"
  fi
done
