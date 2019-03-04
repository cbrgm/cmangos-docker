# Mangos Docker

## Extract map files from client

```
docker run --rm -it -v $(pwd):/output/bin cbrgm/mangos-extractor:latest
```

Copy compiled files from `/bin` to your client directory and run `./ExtractMaps`.

## Run Container

```
docker run -itd \
    --name=mangosd
    -e MYSQL_HOST=127.0.0.1 \
    -e MYSQL_PORT=3306 \
    -e MYSQL_USER=root \
    -e MYSQL_PWD=mangos \
    -e MANGOS_DATABASE_REALM_NAME=testrealm \
    -e MANGOS_GM_ACCOUNT=admin
    -e MANGOS_GM_PWD=changeme
    -v $(pwd)/maps:/opt/mangos/maps \
    -v $(pwd)/vmaps:/opt/mangos/vmaps \
    -v $(pwd)/mmaps:/opt/mangos/mmaps \
    -v $(pwd)/dbc:/opt/mangos/dbc \
    -p 3724:3724 \
    -p 8085:8085 \
    cbrgm/mangos:latest
```

or build your own:

```
docker build -t "mangos:latest" --build-arg=[mangos{two,three,...}] ./mangos
```

## Environment vars:

* `MYSQL_HOST`: MySQL database host ip/dns name
* `MYSQL_PORT`: MySQL database port
* `MYSQL_USER`: MySQL database user
* `MYSQL_PWD`: MySQL database password
* `MANGOS_GM_ACCOUNT`: Gamemaster account name (Default: admin)
* `MANGOS_GM_PWD`: Gamemaster account password (Default: changeme)
* `MANGOS_GAMETYPE`: Realm Gametype (Default: 1 (PVP))
* `MANGOS_MOTD`: Message of the Day (Default: "Welcome!")
* `MANGOS_DATABASE_RELEASE`: Database Migration Release (Default: Rel21)
* `MANGOS_DATABASE_REALM_NAME`: Name of your realm (Default: MyNewServer)
* `MANGOS_SERVER_IP`: IP for mangosd and realmd port binding (Default 0.0.0.0)
* `MANGOS_SERVER_PUBLIC_IP`: Public IP for your mangos server (Default 127.0.0.1)

## Todo:

* Allow external config download via `wget`
* Replace debian9 image with alpine
* Create kubernetes deployment
* Create terraform config for hetzner cloud
