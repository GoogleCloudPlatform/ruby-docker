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

OS_NAME=ubuntu20
RUNTIME_NAME=ruby
PROJECT=
IMAGE_TAG=staging
AUTO_YES=

show_usage() {
  echo 'Usage: release-ruby-runtime-images.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to ubuntu20)' >&2
  echo '  -p <project>: set the project (defaults to current gcloud config setting)' >&2
  echo '  -t <tag>: the image tag to release (defaults to `staging`)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":n:o:p:t:yh" opt; do
  case ${opt} in
    n)
      RUNTIME_NAME=${OPTARG}
      ;;
    o)
      OS_NAME=${OPTARG}
      ;;
    p)
      PROJECT=${OPTARG}
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

OS_BASE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}
OS_SSL10_BASE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/ssl10
RUBY_BASIC_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/basic
BUILD_TOOLS_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/build-tools
GENERATE_DOCKERFILE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/generate-dockerfile

echo
echo "Releasing (i.e. tagging as latest) runtime images:"
echo "  ${OS_BASE_IMAGE}:${IMAGE_TAG}"
if [ "${OS_NAME}" != "ubuntu16" ]; then
  echo "  ${OS_SSL10_BASE_IMAGE}:${IMAGE_TAG}"
fi
echo "  ${RUBY_BASIC_IMAGE}:${IMAGE_TAG}"
echo "  ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG}"
echo "  ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to proceed? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi
echo

gcloud container images add-tag --project ${PROJECT} \
  ${OS_BASE_IMAGE}:${IMAGE_TAG} \
  ${OS_BASE_IMAGE}:latest -q
echo "**** Tagged image ${OS_BASE_IMAGE}:${IMAGE_TAG} as latest"

if [ "${OS_NAME}" != "ubuntu16" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${OS_SSL10_BASE_IMAGE}:${IMAGE_TAG} \
    ${OS_SSL10_BASE_IMAGE}:latest -q
  echo "**** Tagged image ${OS_SSL10_BASE_IMAGE}:${IMAGE_TAG} as latest"
fi

gcloud container images add-tag --project ${PROJECT} \
  ${RUBY_BASIC_IMAGE}:${IMAGE_TAG} \
  ${RUBY_BASIC_IMAGE}:latest -q
echo "**** Tagged image ${RUBY_BASIC_IMAGE}:${IMAGE_TAG} as latest"

gcloud container images add-tag --project ${PROJECT} \
  ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG} \
  ${BUILD_TOOLS_IMAGE}:latest -q
echo "**** Tagged image ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG} as latest"

gcloud container images add-tag --project ${PROJECT} \
  ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG} \
  ${GENERATE_DOCKERFILE_IMAGE}:latest -q
echo "**** Tagged image ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG} as latest"
