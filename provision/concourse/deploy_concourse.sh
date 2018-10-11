#!/bin/bash

set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

source consts.sh
source lib.sh

deploy_concourse
