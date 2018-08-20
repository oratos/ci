#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

source consts.sh
source lib.sh

deploy_concourse
