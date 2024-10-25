#!/bin/bash

if [ "$1" == "" ];
then
	echo "Usage: build-evcc.sh nightly|latest|<version>"
	echo "Where version is in semver format, e.g. 0.125.0"
	exit 1
fi

CLIENT_ID=<YOUR TESLA CLIENT ID>
IMAGE_NAME=<registry location>/evcc

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
	0.124.5|0.124.6|0.124.7|0.124.8|0.124.9|0.124.10)
		PATCHFILE=evcc-tesla-proxy-0.124.10.patch
		;;
	0.125.*|0.126.*|0.127.*|0.128.*|0.129.*|0.130.*)
		PATCHFILE=evcc-tesla-proxy-0.130.13.patch
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

docker build --network=host --no-cache --build-arg TESLA_CLIENT_ID=${CLIENT_ID} ${DOCKER_IMG_TAGS} .

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
