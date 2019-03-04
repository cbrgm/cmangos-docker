FROM gcc:7.3.0 as build

ARG MANGOS_VERSION
ENV MANGOS_BUILDIN_VERSION=${MANGOS_VERSION}

RUN apt-get update -qq \
    && apt-get install openssl libssl-dev cmake -y \
    && git clone https://github.com/${MANGOS_BUILDIN_VERSION}/server.git -b master --recursive \
    && cd server \
    && cmake . -DBUILD_REALMD=1 -DBUILD_MANGOSD=1 -DBUILD_TOOLS=0 -DCONF_DIR=conf/ \
    && make -j4 \
    && make install -j4

FROM debian:9 as image
LABEL title="mangosd" \
    url1="https://cbrgm.net" \
    twitter="@chrisbargmann" \
    maintainer="Christian Bargmann" \
    version="1.0"

ARG MANGOS_VERSION
ENV MYSQL_DATABASE_REALM=realmd \
    MYSQL_DATABASE_WORLD=mangos \
    MYSQL_DATABASE_CHARACTER=characters \
    MANGOS_GM_ACCOUNT=admin \
    MANGOS_GM_PWD=admin \
    MANGOS_GAMETYPE=1 \
    MANGOS_MOTD="Welcome!" \
    MANGOS_DATABASE_RELEASE=Rel21 \
    MANGOS_DATABASE_REALM_NAME=MyNewServer \
    MANGOS_SERVER_IP=0.0.0.0 \
    MANGOS_SERVER_PUBLIC_IP=127.0.0.1 \
    MANGOS_BUILDIN_VERSION=${MANGOS_VERSION}

WORKDIR /opt/mangos
COPY --from=build /server/bin .
COPY entrypoint.sh /usr/local/bin
COPY supervisord.conf /etc/

RUN mkdir -p /opt/mangos \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install wget libstdc++6 libmysql++-dev libssl-dev git mariadb-client mysql-client supervisor -y \
    && mv conf/mangosd.conf.dist conf/mangosd.conf \
    && mv conf/realmd.conf.dist conf/realmd.conf \
    && mkdir -p /var/log/supervisor/ \
    && touch /var/log/supervisord.log \
    && useradd -m -s /bin/bash mangos \
    && chmod a+x bin/mangosd \
    && chmod a+x bin/realmd \
    && chown -R mangos:mangos . \
    && chown -R mangos:mangos /var/log/supervisord.log \
    && chown -R mangos:mangos /var/log/supervisor

USER mangos
EXPOSE 8085/tcp 8085/udp
EXPOSE 3724/tcp 3724/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
