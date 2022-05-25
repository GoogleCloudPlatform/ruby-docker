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
PREBUILT_VERSIONS=()

if [ -f ${DIRNAME}/prebuilt-versions.txt ]; then
  mapfile -t PREBUILT_VERSIONS < ${DIRNAME}/prebuilt-versions.txt
fi

show_usage() {
  echo 'Usage: release-ruby-binary-images.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -c <versions>: comma separated prebuilt ruby versions (defaults to prebuilt-versions.txt)' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to ubuntu20)' >&2
  echo '  -p <project>: set the project (defaults to current gcloud config setting)' >&2
  echo '  -t <tag>: the image tag to release (defaults to `staging`)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":c:n:o:p:t:yh" opt; do
  case ${opt} in
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

PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${RUNTIME_NAME}/${OS_NAME}/prebuilt/ruby-

echo
echo "Releasing (i.e. tagging as latest) binary images:"
for version in "${PREBUILT_VERSIONS[@]}"; do
  echo "  ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG}"
done
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to proceed? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi
echo

for version in "${PREBUILT_VERSIONS[@]}"; do
  gcloud container images add-tag --project ${PROJECT} \
    ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG} \
    ${PREBUILT_IMAGE_PREFIX}${version}:latest -q
  echo "**** Tagged image ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG} as latest"
done
