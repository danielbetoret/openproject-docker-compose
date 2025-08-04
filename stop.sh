#!/bin/bash
set -e

function loadenv() {
    . ./utils/scripts/loadenv.sh < .env
}

# load env variables
loadenv

docker stack down "$DOCKER_STACK_NAME"
