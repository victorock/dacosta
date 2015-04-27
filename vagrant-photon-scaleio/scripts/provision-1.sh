#!/bin/bash

ifconfig eth1 172.16.32.11 netmask 255.255.255.0
ifconfig eth1 up

systemctl enable docker
systemctl start docker
docker run -d -p 9011:9011 -p 7072:7072 --privileged victorock/scaleio:block
