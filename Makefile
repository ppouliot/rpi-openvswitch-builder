SHA := $(shell git rev-parse --short HEAD)
#NAMESPACE :=$(shell cat NAMESPACE)

VERSION :=$(shell cat VERSION)
#PACKAGE_VERSION :=$(shell cat VERSION)
#PACKAGE_RELEASE_VERSION = $(DRONE_BUILD_NUMBER)
#PACKAGE_RELEASE_VERSION ?= 1
#PACKAGE_NAME = swarm_$(PACKAGE_VERSION)-$(PACKAGE_RELEASE_VERSION)_armhf
COMMIT_HASH=$(shell git log --pretty=format:'%h' -n 1)
DATE=$(shell date -Idate)
BUILD_DIR=/build/openvswitch/$(DATE)_$(COMMIT_HASH)

default: prepare compile copy
# upload_to_packagecloud

prepare:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/package
                        
compile:
	docker build -t hypriot/rpi-openvswitch-builder .
	mkdir -p ./builds
	modprobe openvswitch
	lsmod | grep openvswitch
	docker run --rm -ti --cap-add NET_ADMIN -v $(pwd)/builds:/builds hypriot/rpi-openvswitch-builder /bin/bash -c 'DEB_BUILD_OPTIONS="parallel=8 nocheck" fakeroot debian/rules binary && cp /src/*.deb /builds/ && chmod a+rw /builds/*'

copy:
	cp -r builds/* $(BUILD_DIR)/package/
	cd $(BUILD_DIR)/package/ && \
	for i in $(shell ls -1); do \
	shasum -a 256 $(i) >> openvswitch-$VERSION).sha256

upload_to_packagecloud:
	echo "upload debian package to package cloud"
	# see documentation for this api call at https://packagecloud.io/docs/api#resource_packages_method_create
	curl -X POST https://$(PACKAGECLOUD_API_TOKEN):@packagecloud.io/api/v1/repos/Hypriot/Schatzkiste/packages.json \
	     -F "package[distro_version_id]=24" -F "package[package_file]=@$(BUILD_DIR)/package/$(PACKAGE_NAME).deb"
 