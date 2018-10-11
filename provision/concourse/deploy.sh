#!/bin/bash

set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

source consts.sh
source lib.sh

bbl_up
deploy_concourse
