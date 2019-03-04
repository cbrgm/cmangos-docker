##!/bin/bash
set -eu

MANGOS_SERVER_PUBLIC_IP=${MANGOS_SERVER_PUBLIC_IP:-}

# TODO:
# template docker compose
echo $MANGOS_SERVER_PUBLIC_IP

# run docker-compose
