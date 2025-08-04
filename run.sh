#!/bin/bash

function loadenv() {
    . ./utils/scripts/loadenv.sh --uri < .env
    export DATABASE_URL="${DB_DRIVER}://${DB_USERNAME_URIENCODED}:${DB_PASSWORD_URIENCODED}@db/${DB_NAME}?pool=20&encoding=unicode&reconnect=true"
}

# load env variables
loadenv

docker stack deploy \
    --compose-file "${DOCKER_COMPOSE_FILE:-"docker-compose.yaml"}" \
    --detach \
    "$DOCKER_STACK_NAME"
