#!/bin/bash

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
cd $REPO_ROOT_DIR
docker compose build chatgmp
docker compose up chatgmp -d
docker compose exec chatgmp sh -c "/bin/sh"
docker compose down

# docker compose run -it chatgmp sh -c "/bin/sh"