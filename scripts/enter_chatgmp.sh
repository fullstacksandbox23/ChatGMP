#!/bin/bash

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
cd $REPO_ROOT_DIR
docker compose -f compose.yml -f compose.prod.yml build chatgmp
docker compose -f compose.yml -f compose.prod.yml up chatgmp -d
docker compose -f compose.yml -f compose.prod.yml exec chatgmp sh -c "/bin/sh"
docker compose -f compose.yml -f compose.prod.yml down