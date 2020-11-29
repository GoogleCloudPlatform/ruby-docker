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

IMAGE=
ENV_PARAMS=()
SQL_INSTANCES=()
SQL_TIMEOUT=10
STRICT_ERRORS=true
PRE_PULL=true
CONTAINER_NETWORK=cloudbuild

OPTIND=1
while getopts ":e:i:n:s:t:xP" opt; do
  case $opt in
    e)
      ENV_PARAMS+=(-e "$OPTARG")
      ;;
    i)
      IMAGE=$OPTARG
      ;;
    n)
      CONTAINER_NETWORK=$OPTARG
      ;;
    s)
      SQL_INSTANCES+=("$OPTARG")
      ;;
    t)
      SQL_TIMEOUT=$OPTARG
      ;;
    x)
      STRICT_ERRORS=
      ;;
    P)
      PRE_PULL=
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option $OPTARG requires a parameter" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${IMAGE}" ]; then
  >&2 echo "ERROR: Docker image expected"
  exit 1
fi

CONTAINER=$(cat /proc/1/cgroup | sed -n 's|^.*/docker/\([a-f0-9]*\)|\1|p' | awk 'NR==1')
if [ -z "$CONTAINER" ]; then
  CONTAINER=$(basename $(cat /proc/1/cpuset))
fi
if [ -z "$CONTAINER" ]; then
  >&2 echo "ERROR: Unable to determine current container"
  exit 1
fi

if [ -n "$PRE_PULL" ]; then
  echo
  echo "---------- INSTALL IMAGE ----------"
  docker pull ${IMAGE}
fi

SQL_INSTANCES=$(IFS=,; echo "${SQL_INSTANCES[*]}")
if [ -n "${SQL_INSTANCES}" ]; then
  echo
  echo "---------- CONNECT CLOUDSQL ----------"
  touch cloud_sql_proxy.log
  /buildstep/cloud_sql_proxy -dir=/cloudsql -instances=${SQL_INSTANCES} > cloud_sql_proxy.log 2>&1 &
  if (timeout ${SQL_TIMEOUT}s tail -f --lines=+1 cloud_sql_proxy.log &) | grep -qe 'Ready for new connections'; then
    echo "cloud_sql_proxy is running."
  else
    >&2 echo "ERROR: Failed to start cloud_sql_proxy"
    >&2 cat cloud_sql_proxy.log
    [ -n "$STRICT_ERRORS" ] && exit 1
  fi
fi

echo
echo "---------- EXECUTE COMMAND ----------"
echo "$@"
docker run --rm --volumes-from=${CONTAINER} --network=${CONTAINER_NETWORK} "${ENV_PARAMS[@]}" ${IMAGE} "$@"

echo
echo "---------- CLEANUP ----------"
