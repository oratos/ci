#!/bin/bash

set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

source consts.sh
source lib.sh

delete_concourse
bbl_down
