#!/bin/bash

# When CloudBuild runs this script via docker run, it sets the dir to
# /workspace, which may have a .ruby-version that is not supported by the
# base image. So cd back into /build-step before running Ruby.
cd /buildstep
ruby build_script.rb "$@"
