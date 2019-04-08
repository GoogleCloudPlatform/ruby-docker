#!/bin/bash
export KOKORO_GITHUB_DIR=${KOKORO_ROOT}/src/github
source ${KOKORO_GFILE_DIR}/kokoro/common.sh

RUNTIME_NAME="ruby"

if [ -z "${TAG}" ]; then
  TAG=`date +%Y-%m-%d-%H%M%S`
fi

STAGING_FLAG=
if [ "${UPLOAD_TO_STAGING}" = "true" ]; then
  STAGING_FLAG="-s"
fi


cd ${KOKORO_GITHUB_DIR}/ruby-docker
./build-ruby-runtime-images.sh -i -p $BUILDER_PROJECT -t $TAG $STAGING_FLAG -y

METADATA=${KOKORO_GITHUB_DIR}/ruby_docker/METADATA
cd ${KOKORO_GFILE_DIR}/kokoro
python note.py ruby -m ${METADATA} -t ${TAG}
