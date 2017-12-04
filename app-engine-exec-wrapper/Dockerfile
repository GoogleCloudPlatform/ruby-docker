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

FROM gcr.io/cloud-builders/docker:latest

# Install cloud_sql_proxy and share the /cloudsql volume.
RUN mkdir /buildstep \
    && mkdir /cloudsql \
    && curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 \
        > /buildstep/cloud_sql_proxy \
    && chmod a+x /buildstep/cloud_sql_proxy
VOLUME /cloudsql

# Starts CloudSQL and runs a given docker image.
COPY execute.sh /buildstep/execute.sh
ENTRYPOINT ["/buildstep/execute.sh"]
