##!/bin/bash
set -eu

sleep 20

# use noninteractive to disable prompts during apt install
export DEBIAN_FRONTEND=noninteractive

apt-get -qq update && apt-get -qq upgrade -y
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
  git \
  wget

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
  stable"

apt-get update -y

# apt-cache madison docker-ce
apt-get install -y docker-ce docker-compose
