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
PROJECT=
RUNTIME_VERSION=staging
AUTO_YES=

show_usage() {
  echo 'Usage: release-ruby-runtime-pipeline.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -b <bucket>: promote the runtime definition in this gcs bucket (required)' >&2
  echo '  -n <name>: set the runtime name (defaults to `ruby`)' >&2
  echo '  -p <project>: set the builder images project (defaults to current gcloud config setting)' >&2
  echo '  -r <version>: release this runtime (defaults to staging)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":b:n:p:t:yh" opt; do
  case ${opt} in
    b)
      UPLOAD_BUCKET=${OPTARG}
      ;;
    n)
      RUNTIME_NAME=${OPTARG}
      ;;
    p)
      PROJECT=${OPTARG}
      ;;
    r)
      RUNTIME_VERSION=${OPTARG}
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

SOURCE_GS_URL=gs://${UPLOAD_BUCKET}/${RUNTIME_NAME}-default-builder-${RUNTIME_VERSION}.yaml
RELEASE_GS_URL=gs://${UPLOAD_BUCKET}/${RUNTIME_NAME}-default-builder.yaml

echo
echo "Releasing runtime: ${SOURCE_GS_URL}"
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to proceed? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

gsutil cp ${SOURCE_GS_URL} ${RELEASE_GS_URL}
echo "**** Promoted runtime config ${SOURCE_GS_URL} to ${RELEASE_GS_URL}"
