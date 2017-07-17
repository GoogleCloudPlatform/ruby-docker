#!/bin/bash

set -e

DIRNAME=$(dirname $0)

$DIRNAME/build_step.sh build_app $@
$DIRNAME/build_step.sh gen_dockerfile $@
