#!/bin/bash
export KOKORO_GITHUB_DIR=${KOKORO_ROOT}/src/github
source ${KOKORO_GFILE_DIR}/kokoro/common.sh


if [ -z "${TAG}" ]; then
  TAG=`date +%Y-%m-%d-%H%M%S`
fi

STAGING_FLAG=
if [ "${UPLOAD_TO_STAGING}" = "true" ]; then
  STAGING_FLAG="-s"
fi


if [ -z "$RUBY_VERSIONS" ]; then
  echo "**** No Ruby versions specified."
  echo "**** You must set the RUBY_VERSIONS environment variable to a colon-delimited list."
  exit 1
fi

RUBY_VERSIONS=$( echo "$RUBY_VERSIONS" | tr : , )

cd ${KOKORO_GITHUB_DIR}/ruby-docker
./build-ruby-binary-images.sh -p $BUILDER_PROJECT -t $TAG $STAGING_FLAG -c $RUBY_VERSIONS -y
