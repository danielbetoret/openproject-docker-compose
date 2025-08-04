#!/bin/bash
set -e

function loadenv() {
    . ./utils/scripts/loadenv.sh < .env
}

function unloadenv() {
    . ./utils/scripts/unloadenv.sh < .env
}

# load env varibles
loadenv

# check if docker stack name is setup correctly
if [[ -v DOCKER_STACK_NAME ]]; then
    if [[ $(docker stack ls | grep "$DOCKER_STACK_NAME") ]]; then
        echo stack with name "$DOCKER_STACK_NAME" already exists
        exit 1
    fi
else
    echo please set your stack name in the setup.env file
    exit 1
fi

# check if docker data mount root
if [[ -v DATA_MNT_ROOT ]]; then
    echo "-> great! DATA_MNT_ROOT is set up correctly"
else
    echo please set your data mount root in the setup.env file
    exit 1
fi

# create necessary volumes
echo "-> creating necessary volumes"
if [[ $(docker volume ls | grep "${DOCKER_STACK_NAME}_db_data") ]]; then
    echo "db volume already exists"
else
    # create folder for persistent data if not exists
    mkdir -p $DATA_MNT_ROOT/db/data

    docker volume create \
        -d local \
        --opt type=none \
        --opt o=bind \
        --opt device=${DATA_MNT_ROOT}/db/data \
        ${DOCKER_STACK_NAME}_db_data

    echo "created db volume"
fi

if [[ $(docker volume ls | grep "${DOCKER_STACK_NAME}_openproject_data") ]]; then
    echo "openproject volume already exists"
else
    # create folder for persistent data if not exists
    mkdir -p $DATA_MNT_ROOT/openproject/data

    docker volume create \
        --driver local \
        --opt type=none \
	    --opt o=bind \
	    --opt device=$DATA_MNT_ROOT/openproject/data \
	    ${DOCKER_STACK_NAME}_openproject_data

    echo "created openproject volume"
fi

# pull all images
echo "-> downloading images"
if [[ $(docker image ls | grep "openproject/openproject *${TAG:-16-slim}") ]]; then
    echo "openproject image already downloaded"
else
    docker pull "openproject/openproject:${TAG:-16-slim}" &> /dev/null
    echo "pulled openproject image"
fi

if [[ $(docker image ls | grep -E "postgres *13") ]]; then
    echo "db image already downloaded"
else
    docker pull postgres:13 &> /dev/null
    echo "pulled db image"
fi

if [[ $(docker image ls | grep "memcached") ]]; then
    echo "memcached image already downloaded"
else
    docker pull memcached &> /dev/null
    echo "pulled memcached image"
fi

if [[ $(docker image ls | grep -E 'willfarrell/autoheal *1\.2\.0') ]]; then
    echo "autoheal image already downloaded"
else
    docker pull willfarrell/autoheal:1.2.0 &> /dev/null
    echo "pulled autoheal image"
fi

# build other images
echo "-> building necessary images"
if [[ $(docker image ls | grep "${DOCKER_STACK_NAME}_proxy") ]]; then
    echo "proxy image already built"
else
    docker build \
        --build-arg APP_HOST=web \
        --tag "${DOCKER_STACK_NAME}_proxy" \
        ./proxy \
        &> /dev/null
    echo "built proxy image"
fi

# cleanup
unloadenv
