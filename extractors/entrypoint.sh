#!/bin/sh
# This entrypoint script downloads and compiles the latest mangos extractors from source.

MANGOS_REPO=https://github.com/cmangos/mangos-wotlk.git

# Clone the repository
echo "cloning mangos repository"
git clone ${MANGOS_REPO} -b master --recursive /server
mkdir -p /server/build
cd /server/build

# Build extractors
cmake .. -DCMAKE_INSTALL_PREFIX=/server -DBUILD_GAME_SERVER=0 -DBUILD_LOGIN_SERVER=0 -DBUILD_EXTRACTORS=1 -DPCH=1 -DBUILD_PLAYERBOT=0
make -j4
make install -j4

# Copy all needed files for data extraction
mkdir -p /output/bin
cp -r /server/contrib/extractor_scripts/* /output/bin
cp -r /server/bin/tools/* /output/bin
