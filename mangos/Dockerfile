FROM gcc:7.3.0 as build

RUN apt-get update -qq \
    && apt-get install build-essential gcc g++ automake git-core autoconf make patch libmysql++-dev mysql-server libtool libssl-dev grep binutils zlibc libc6 libbz2-dev cmake subversion libboost-all-dev -y \
    && git clone https://github.com/cmangos/mangos-wotlk.git -b master --recursive server \
    && mkdir -p server/build \
    && cd server/build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/server -DBUILD_GAME_SERVER=1 -DBUILD_LOGIN_SERVER=1 -DBUILD_EXTRACTORS=0 -DPCH=1 -DBUILD_PLAYERBOT=1 \
    && make -j4 \
    && make install -j4

FROM debian:9 as image
LABEL title="cmangos docker" \
    url1="https://cbrgm.net" \
    twitter="@chrisbargmann" \
    maintainer="Christian Bargmann" \
    version="1.0"

ARG MANGOS_VERSION
ENV MYSQL_DATABASE_REALM=wotlkrealmd \
    MYSQL_DATABASE_WORLD=wotlkmangos \
    MYSQL_DATABASE_CHARACTER=wotlkcharacters \
    MYSQL_MANGOS_USER=mangos \
    MYSQL_MANGOS_PWD=mangos \
    MANGOS_GM_ACCOUNT=admin \
    MANGOS_GM_PWD=admin \
    MANGOS_GAMETYPE=1 \
    MANGOS_MOTD="Welcome!" \
    MANGOS_REALM_NAME=MyNewServer \
    MANGOS_SERVER_IP=0.0.0.0 \
    MANGOS_SERVER_PUBLIC_IP=127.0.0.1 \
    MANGOS_ALLOW_PLAYERBOTS=0 \
    MANGOS_ALLOW_AUCTIONBOT_SELLER=0 \
    MANGOS_ALLOW_AUCTIONBOT_BUYER=0

WORKDIR /opt/mangos
COPY --from=build /server/bin bin
COPY --from=build /server/etc etc
COPY --from=build /server/src/game/AuctionHouseBot/ahbot.conf.dist.in etc/ahbot.conf.dist
COPY entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/

RUN mkdir -p /opt/mangos \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install wget libssl-dev git mariadb-client mysql-client supervisor -y \
    && mv etc/mangosd.conf.dist etc/mangosd.conf \
    && mv etc/realmd.conf.dist etc/realmd.conf \
    && mv etc/realmd.conf.dist etc/ahbot.conf \
    && mv etc/playerbot.conf.dist etc/playerbot.conf \
    && mkdir -p /var/log/supervisor/ \
    && touch /var/log/supervisord.log \
    && useradd -m -s /bin/bash mangos \
    && chmod a+x bin/* \
    && chown -R mangos:mangos . \
    && chown -R mangos:mangos /var/log/supervisord.log \
    && chown -R mangos:mangos /var/log/supervisor

USER mangos
EXPOSE 8085/tcp 8085/udp
EXPOSE 3724/tcp 3724/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
