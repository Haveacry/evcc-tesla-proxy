#!/bin/bash

if [ "$1" == "" ];
then
        echo "Usage: build-evcc.sh nightly|latest|<version>"
        echo "Where version is in semver format, e.g. 0.125.0"
        exit 1
fi

#CLIENT_ID=9a6e7b0f6d25-4d74-a41e-ffb0c1237cf9
IMAGE_NAME=registry.haveacry.com/evcc

case $1 in
        nightly)
                EVCC_VERSION=nightly
                NIGHTLYVER=`date +"%Y%m%d"`
                DOCKER_IMG_TAGS="-t ${IMAGE_NAME}:nightly -t ${IMAGE_NAME}:nightly-${NIGHTLYVER}"
                BRANCH=master
                ;;
        latest)
                CURRENT_VER=`cat .evcclatest`
                EVCC_VERSION=`curl -s https://api.github.com/repos/evcc-io/evcc/releases/latest | jq -r '.tag_name'`
                BRANCH=${EVCC_VERSION}
                DOCKER_IMG_TAGS="--build-arg RELEASE=1 -t ${IMAGE_NAME}:${EVCC_VERSION} -t ${IMAGE_NAME}:latest"

                if [ "$CURRENT_VER" == "$EVCC_VERSION" ];
                then
                        echo "You have already built the latest EVCC version"
                        exit 1
                fi
                ;;
        0.*)
                EVCC_VERSION=$1
                BRANCH=${EVCC_VERSION}
                DOCKER_IMG_TAGS="--build-arg RELEASE=1 -t ${IMAGE_NAME}:${EVCC_VERSION}"
                ;;
        *)
                echo "Usage: build-evcc.sh nightly|latest|<version>"
                echo "Where version is in semver format, e.g. 0.125.0"
                exit 1
                ;;
esac

if [ -d evcc ];
then
        rm -rf evcc
fi

git clone https://github.com/evcc-io/evcc --branch ${BRANCH}

if [ $? -ne 0 ];
then
        echo "Unable to clone GitHub repository. Please check version is correct and there is connectivity to GitHub"
        exit 1
fi

cd evcc

case ${EVCC_VERSION} in
        0.124.4)
                PATCHFILE=evcc-tesla-proxy-0.124.4.patch
                ;;
        0.124.[5-9]|0.124.10)
                PATCHFILE=evcc-tesla-proxy-0.124.10.patch
                ;;
        0.12[5-9].*|0.130.*)
                PATCHFILE=evcc-tesla-proxy-0.130.13.patch
                ;;
        0.131.*|0.132.0|0.132.1)
                PATCHFILE=evcc-tesla-proxy-0.132.1.patch
                ;;
        0.133.*|0.20[0-2].*|0.203.[0-5])
                PATCHFILE=evcc-tesla-proxy-0.203.5.patch
                ;;
	0.203.6|0.20[4-9].*|0.21[01].*|0.30[0-8].*|0.309.0)
		PATCHFILE=evcc-tesla-proxy-0.309.0.patch
		;;
        *)
                PATCHFILE=evcc-tesla-proxy-nightly.patch
                ;;
esac

patch -p1 --ignore-whitespace < ../${PATCHFILE}

if [ $? -ne 0 ];
then
        echo "Patch failed to apply, please review source code for changes"
        exit 1
fi

docker build --network=host --no-cache ${DOCKER_IMG_TAGS} .

case $1 in
        "nightly")
                docker push $IMAGE_NAME:nightly
                docker push ${IMAGE_NAME}:nightly-${NIGHTLYVER}
                ;;
        "latest")
                docker push $IMAGE_NAME:$EVCC_VERSION
                docker push $IMAGE_NAME:latest
                cd ..
                echo $EVCC_VERSION > .evcclatest
                ;;
esac
