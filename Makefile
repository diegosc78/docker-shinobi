GITREPO ?= https://gitlab.com/Shinobi-Systems/Shinobi.git
GITBRANCH ?= master
NS ?= docker.io/ponte124
VERSION ?= 26.5.9
IMAGE_NAME ?= shinobi

common:
	mkdir -p ./ShinobiData

clean:
	rm -rf ./ShinobiSource

download: common clean
	git clone --branch $(GITBRANCH) $(GITREPO) ShinobiSource
	cp ./Dockerfile ./ShinobiSource/
	cp ./init.sh ./ShinobiSource/Docker/
	cp ./.dockerignore ./ShinobiSource/

build: download
	docker build -t $(NS)/$(IMAGE_NAME):$(VERSION) -t $(NS)/$(IMAGE_NAME):latest -f Dockerfile ${PWD}/ShinobiSource

buildx: download
	docker buildx build --platform linux/amd64,linux/arm64 -t $(NS)/$(IMAGE_NAME):$(VERSION) -t $(NS)/$(IMAGE_NAME):latest --push -f Dockerfile ${PWD}/ShinobiSource

push:
	docker tag $(NS)/$(IMAGE_NAME):$(VERSION) $(NS)/$(IMAGE_NAME):latest
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)
	docker push $(NS)/$(IMAGE_NAME):latest

sbom:
	mkdir -p ./ShinobiData/sbom
	docker scout sbom --format cyclonedx --output ./ShinobiData/sbom/$(IMAGE_NAME)-$(VERSION)-scout.json $(NS)/$(IMAGE_NAME):$(VERSION)