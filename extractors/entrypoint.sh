#!/bin/sh
# This entrypoint script downloads and compiles the latest mangos extractors from source.

MANGOS_REPO=https://github.com/mangostwo/server.git

echo "cloning mangos repository"
git clone ${MANGOS_REPO} -b master --recursive /server
cd /server

cmake . -DBUILD_REALMD=0 -DBUILD_MANGOSD=0 -DBUILD_TOOLS=1 -DCONF_DIR=conf/ && \
make -j4
make install -j4

cp -r /server/bin/bin/tools /output/bin
