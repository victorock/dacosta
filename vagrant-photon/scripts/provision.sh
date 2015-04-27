#!/bin/bash

systemctl enable docker
systemctl start docker
docker run -d -p 80:80 vmwarecna/nginx
