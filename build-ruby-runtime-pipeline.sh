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
OS_NAME=ubuntu20
RUNTIME_NAME=ruby
PROJECT=
RUNTIME_VERSION=
IMAGE_TAG=
STAGING_FLAG=
AUTO_YES=
PREBUILT_IMAGE_TAG=latest
PREBUILT_VERSIONS=()

if [ -f ${DIRNAME}/prebuilt-versions.txt ]; then
  mapfile -t PREBUILT_VERSIONS < ${DIRNAME}/prebuilt-versions.txt
fi

show_usage() {
  echo 'Usage: build-ruby-runtime-pipeline.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -a <tag>: use this prebuilt image tag (defaults to `latest`)' >&2
  echo '  -b <bucket>: upload a new runtime definition to this gcs bucket (required)' >&2
  echo '  -c <versions>: comma separated prebuilt ruby versions (defaults to prebuilt-versions.txt)' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -o <osname>: use the given os base image (defaults to ubuntu20)' >&2
  echo '  -p <project>: set the builder images project (defaults to current gcloud config setting)' >&2
  echo '  -r <version>: set the runtime release (defaults to create a new version)' >&2
  echo '  -s: also upload a staging runtime pipeline (defaults to false)' >&2
  echo '  -t <tag>: use the given image tag (defaults to latest)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":a:b:c:n:o:p:q:r:st:yh" opt; do
  case ${opt} in
    a)
      PREBUILT_IMAGE_TAG=${OPTARG}
      ;;
    b)
      UPLOAD_BUCKET=${OPTARG}
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
    q)
      PROJECT=${OPTARG}
      ;;
    r)
      RUNTIME_VERSION=${OPTARG}
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

if [ -z "${UPLOAD_BUCKET}" ]; then
  echo "Error: -b flag is required." >&2
  echo >&2
  show_usage
  exit 1
fi

if [ -z "${PROJECT}" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using builder image project from gcloud config: ${PROJECT}" >&2
fi

if [ -z "${RUNTIME_VERSION}" ]; then
  RUNTIME_VERSION=$(date +%Y%m%d%H%M%S)
  echo "Creating new RUNTIME_VERSION: ${RUNTIME_VERSION}" >&2
fi

GENERATE_DOCKERFILE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/generate-dockerfile
RUBY_OS_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}
BUILD_TOOLS_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/build-tools
PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/prebuilt/ruby-
VERSIONED_GS_URL=gs://${UPLOAD_BUCKET}/${RUNTIME_NAME}-default-builder-${RUNTIME_VERSION}.yaml
STAGING_GS_URL=gs://${UPLOAD_BUCKET}/${RUNTIME_NAME}-default-builder-staging.yaml

PREBUILT_IMAGE_ARGS=
for version in "${PREBUILT_VERSIONS[@]}"; do
  tag=$(gcloud container images list-tags ${PREBUILT_IMAGE_PREFIX}${version} --filter=tags=${PREBUILT_IMAGE_TAG} --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  if [ -z "${tag}" ]; then
    tag=${PREBUILT_IMAGE_TAG}
  fi
  echo "Tag for prebuilt ruby ${version}: ${tag}" >&2
  PREBUILT_IMAGE_ARGS="${PREBUILT_IMAGE_ARGS} '-p', '${version}=${PREBUILT_IMAGE_PREFIX}${version}:${tag}',"
done

DEFAULT_RUBY_VERSION=${PREBUILT_VERSIONS[${#PREBUILT_VERSIONS[@]}-1]}

if [ -z "${IMAGE_TAG}" ]; then
  IMAGE_TAG=latest
fi
if [ "${IMAGE_TAG}" = "staging" -o "${IMAGE_TAG}" = "latest" ]; then
  SYMBOL=${IMAGE_TAG}
  IMAGE_TAG=$(gcloud container images list-tags ${GENERATE_DOCKERFILE_IMAGE} --filter=tags=${SYMBOL} --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting IMAGE_TAG to ${SYMBOL}: ${IMAGE_TAG}" >&2
fi

echo
echo "Creating and uploading a new runtime config:"
echo "  ${VERSIONED_GS_URL}"
if [ "${STAGING_FLAG}" = "true" ]; then
  echo "  ${STAGING_GS_URL}"
else
  echo "but NOT uploading it as staging."
fi
echo "It references:"
echo "  ${RUBY_OS_IMAGE}:${IMAGE_TAG}"
echo "  ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG}"
echo "  ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
echo "Default Ruby version is ${DEFAULT_RUBY_VERSION}"
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

echo
mkdir -p ${DIRNAME}/tmp
sed -e "s|@@GENERATE_DOCKERFILE_IMAGE@@|${GENERATE_DOCKERFILE_IMAGE}|g;\
        s|@@RUBY_OS_IMAGE@@|${RUBY_OS_IMAGE}|g;\
        s|@@BUILD_TOOLS_IMAGE@@|${BUILD_TOOLS_IMAGE}|g;\
        s|@@PREBUILT_IMAGE_ARGS@@|${PREBUILT_IMAGE_ARGS}|g;\
        s|@@TAG@@|${IMAGE_TAG}|g;\
        s|@@DEFAULT_RUBY_VERSION@@|${DEFAULT_RUBY_VERSION}|g" \
  < ${DIRNAME}/ruby-pipeline/ruby-template.yaml.in > ${DIRNAME}/tmp/ruby-${RUNTIME_VERSION}.yaml
gsutil cp ${DIRNAME}/tmp/ruby-${RUNTIME_VERSION}.yaml ${VERSIONED_GS_URL}
echo "**** Uploaded runtime config to ${VERSIONED_GS_URL}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gsutil cp ${VERSIONED_GS_URL} ${STAGING_GS_URL}
  echo "**** Also promoted runtime config to ${STAGING_GS_URL}"
fi
