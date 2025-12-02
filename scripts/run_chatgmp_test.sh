#!/bin/sh


REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
cd $REPO_ROOT_DIR
docker compose -f compose.yml -f compose.test.yml build chatgmp
docker compose -f compose.yml -f compose.test.yml up chatgmp
docker compose -f compose.yml -f compose.test.yml down chatgmp