#!/bin/bash
docker-machine create -d vmwarefusion \
--vmwarefusion-boot2docker-url https://github.com/cloudnativeapps/boot2docker/releases/download/v1.6.0-vmw/boot2docker-1.6.0-vmw.iso \
local-fusion

eval "$(docker-machine env local-fusion)"

token=$(docker run swarm create 2>&1 | tail -n 1)

docker-machine create -d vmwarefusion \
--vmwarefusion-boot2docker-url https://github.com/cloudnativeapps/boot2docker/releases/download/v1.6.0-vmw/boot2docker-1.6.0-vmw.iso \
--swarm \
--swarm-master \
--swarm-discovery token://$token \
swarm-master

docker-machine create -d vmwarefusion \
--vmwarefusion-boot2docker-url https://github.com/cloudnativeapps/boot2docker/releases/download/v1.6.0-vmw/boot2docker-1.6.0-vmw.iso \
--swarm \
--swarm-discovery token://$token \
swarm-node01

docker-machine create -d vmwarefusion \
--vmwarefusion-boot2docker-url https://github.com/cloudnativeapps/boot2docker/releases/download/v1.6.0-vmw/boot2docker-1.6.0-vmw.iso \
--swarm \
--swarm-discovery token://$token \
swarm-node02

eval $(docker-machine env --swarm swarm-master)

docker-compose up -d
