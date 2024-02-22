#!/bin/bash

EVCC_VERSION=0.124.4
CLIENT_ID=<YOUR TESLA CLIENT ID>
IMAGE_NAME=<registry location>/evcc

if [ -d evcc ];
then
	rm -rf evcc
fi

git clone https://github.com/evcc-io/evcc --branch ${EVCC_VERSION}

cd evcc

patch -p1 --ignore-whitespace < ../evcc-tesla-proxy.patch

docker build --network=host --no-cache --build-arg TESLA_CLIENT_ID=${CLIENT_ID} -t ${IMAGE_NAME}:${EVCC_VERSION} -t ${IMAGE_NAME}:latest .

docker push $IMAGE_NAME:$EVCC_VERSION
docker push $IMAGE_NAME:latest
