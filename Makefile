# Set preferred rancher version.
VERSION=v2.0.4

# Set rancher persistent storage for volume mapping.
STORAGE=${PWD}/data
BACKUP=${PWD}/backup

# Don't touch!
SHELL:=/bin/bash
IMAGE=rancher/rancher
NAME=rancher
FILENAME=`date "+%Y-%m-%d"`-backup-rancher-${VERSION}

.PHONY: setup
setup:
	# make the storage path unless it already exists.
	@mkdir -p ${STORAGE}

.PHONY: pull
pull:
	docker pull ${IMAGE}:${VERSION}

.PHONY: start
start: setup pull
	docker run -d --restart=unless-stopped \
  		--name ${NAME} \
  		-v ${STORAGE}:/var/lib/rancher \
  		-p 80:80 -p 443:443 \
  		${IMAGE}:${VERSION}

.PHONY: exists
exists:
	@if [ "`docker ps -aq -f name=${NAME}`" = "" ]; then echo "Rancher doesn't exist" && exit 1; fi

# There's no point in just stopping, so wipe it.
.PHONY: destroy
destroy: exists
	docker rm -f ${NAME}


# rancher single-host does not support hot backup. restart docker in the meanwhile.
.PHONY: backup
backup: exists
	@mkdir -p ${BACKUP}
	@echo "Backing up to : ${FILENAME}"
	docker stop ${NAME}
	tar zcvf ${BACKUP}/${FILENAME}.tgz ${STORAGE}
	docker start ${NAME}
