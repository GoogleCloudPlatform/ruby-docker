#!/bin/bash

# When CloudBuild runs this script via docker run, it sets the dir to the
# workspace, which may have a .ruby-version that is not supported by the
# base image. So cd back into /buildstep before running Ruby, and pass the
# original working directory into the script.
WORKSPACE_DIR=$(/bin/pwd)
cd /buildstep
ruby build_script.rb --workspace-dir=$WORKSPACE_DIR "$@"
