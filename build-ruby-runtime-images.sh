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


# This is the Ruby version that is installed in the "basic" convenience image
# and that is used to run generate-dockerfile. It is NOT the same as the Ruby
# version used by the runtime by default if one is not specified by the app.
BASIC_RUBY_VERSION=2.6.8

BUNDLER1_VERSION=1.17.3
BUNDLER2_VERSION=2.1.4
NODEJS_VERSION=14.16.1
GCLOUD_VERSION=334.0.0


set -e

DIRNAME=$(dirname $0)

OS_NAME=ubuntu16
RUNTIME_NAME=ruby
BASE_IMAGE_DOCKERFILE=default
PROJECT=
IMAGE_TAG=
STAGING_FLAG=
AUTO_YES=

show_usage() {
  echo 'Usage: build-ruby-runtime-images.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -i: use prebuilt ruby to build base image' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to `ubuntu16`)' >&2
  echo '  -p <project>: set the project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":in:o:p:q:st:yh" opt; do
  case ${opt} in
    i)
      BASE_IMAGE_DOCKERFILE="prebuilt"
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

OS_BASE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}
RUBY_BASIC_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/basic
BUILD_TOOLS_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/build-tools
GENERATE_DOCKERFILE_IMAGE=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/generate-dockerfile
PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/prebuilt/ruby-

echo
echo "Building base, tools, and dockerfile generator images:"
echo "  ${OS_BASE_IMAGE}:${IMAGE_TAG}"
echo "  ${RUBY_BASIC_IMAGE}:${IMAGE_TAG}"
echo "  ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG}"
echo "  ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
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

gcloud builds submit ${DIRNAME}/ruby-${OS_NAME} \
  --config ${DIRNAME}/ruby-${OS_NAME}/cloudbuild.yaml --project ${PROJECT} \
  --substitutions _IMAGE=${OS_BASE_IMAGE},_TAG=${IMAGE_TAG},_BUNDLER_VERSION=${BUNDLER2_VERSION},_NODEJS_VERSION=${NODEJS_VERSION}
echo "**** Built image: ${OS_BASE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${OS_BASE_IMAGE}:${IMAGE_TAG} ${OS_BASE_IMAGE}:staging -q
  echo "**** And tagged as ${OS_BASE_IMAGE}:staging"
fi

sed -e "s|@@RUBY_OS_IMAGE@@|ruby-${OS_NAME}|g; s|@@PREBUILT_RUBY_IMAGE@@|${PREBUILT_IMAGE_PREFIX}${BASIC_RUBY_VERSION}|g" \
  < ${DIRNAME}/ruby-base/Dockerfile-${BASE_IMAGE_DOCKERFILE}.in > ${DIRNAME}/ruby-base/Dockerfile
gcloud builds submit ${DIRNAME}/ruby-base \
  --config ${DIRNAME}/ruby-base/cloudbuild.yaml --project ${PROJECT} --timeout 20m \
  --substitutions _OS_NAME=${OS_NAME},_OS_BASE_IMAGE=${OS_BASE_IMAGE},_IMAGE=${RUBY_BASIC_IMAGE},_TAG=${IMAGE_TAG},_RUBY_VERSION=${BASIC_RUBY_VERSION},_BUNDLER1_VERSION=${BUNDLER1_VERSION},_BUNDLER2_VERSION=${BUNDLER2_VERSION}
echo "**** Built image: ${RUBY_BASIC_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${RUBY_BASIC_IMAGE}:${IMAGE_TAG} ${RUBY_BASIC_IMAGE}:staging -q
  echo "**** And tagged as ${RUBY_BASIC_IMAGE}:staging"
fi

gcloud builds submit ${DIRNAME}/ruby-build-tools \
  --config ${DIRNAME}/ruby-build-tools/cloudbuild.yaml --project ${PROJECT} \
  --substitutions _BASE_IMAGE=${RUBY_BASIC_IMAGE},_IMAGE=${BUILD_TOOLS_IMAGE},_TAG=${IMAGE_TAG},_GCLOUD_VERSION=${GCLOUD_VERSION},_BUNDLER1_VERSION=${BUNDLER1_VERSION},_BUNDLER2_VERSION=${BUNDLER2_VERSION}
echo "**** Built image: ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${BUILD_TOOLS_IMAGE}:${IMAGE_TAG} ${BUILD_TOOLS_IMAGE}:staging -q
  echo "**** And tagged as ${BUILD_TOOLS_IMAGE}:staging"
fi

gcloud builds submit ${DIRNAME}/ruby-generate-dockerfile \
  --config ${DIRNAME}/ruby-generate-dockerfile/cloudbuild.yaml --project ${PROJECT} \
  --substitutions _BASE_IMAGE=${RUBY_BASIC_IMAGE},_IMAGE=${GENERATE_DOCKERFILE_IMAGE},_TAG=${IMAGE_TAG},_BUNDLER1_VERSION=${BUNDLER1_VERSION},_BUNDLER2_VERSION=${BUNDLER2_VERSION}
echo "**** Built image: ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG} ${GENERATE_DOCKERFILE_IMAGE}:staging -q
  echo "**** And tagged as ${GENERATE_DOCKERFILE_IMAGE}:staging"
fi
