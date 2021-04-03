NS ?= ponte124
VERSION ?= latest-arm64v8
IMAGE_NAME ?= shinobi
CONTAINER_NAME ?= shinobi
CONTAINER_INSTANCE ?= manual

build: 
	rm -rf ./ShinobiSource
	git clone https://gitlab.com/Shinobi-Systems/Shinobi.git ShinobiSource
	cp ./Dockerfile.arm64v8 ./ShinobiSource/
	cp ./.dockerignore ./ShinobiSource/
	docker build -t $(NS)/$(IMAGE_NAME):$(VERSION) -f Dockerfile.arm64v8 ${PWD}/ShinobiSource

push:
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)
