#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

source consts.sh
source lib.sh

delete_concourse
bbl_down
