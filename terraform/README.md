# cMangos Docker

## Terraform config

Terraform config to start a new mangos server instance on hetzner cloud.
Edit `/hack/build.sh` and alter the docker-compose.yml.

Run:

```
terraform init
```

and

```
terraform apply
```

## Requirements:

The config will copy over all required extracted map data for mangos.
All extracted map files must be in a folder `../resources/resources.tar.gz`

tar archive must contain the following folders and data

```
./resources/maps
./resources/vmaps
./resources/mmaps
./resources/dbc
```
