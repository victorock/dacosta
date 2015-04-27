#!/bin/bash

ifconfig eth1 172.16.33.13 netmask 255.255.255.0
ifconfig eth1 up

systemctl enable docker
systemctl start docker
docker run -d -p 80:80 -p 443:443 -p 6611:6611 -p 9011:9011 -p 7072:7072 --privileged -e IP_DOCKER_HOST=172.16.33.13 -e IP_SECONDARY_MDM=172.16.33.12 -e IP_TB=172.16.33.11 -e DEVICE_LIST=/dev/sdb,/dev/sdc victorock/scaleio:primary
