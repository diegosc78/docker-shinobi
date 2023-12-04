GITREPO ?= https://gitlab.com/Shinobi-Systems/Shinobi.git
GITBRANCH ?= master
NS ?= docker.io/ponte124
VERSION ?= 23.12
IMAGE_NAME ?= shinobi

common:
	mkdir -p ./ShinobiData

clean:
	rm -rf ./ShinobiSource

build: common clean
	git clone --branch $(GITBRANCH) $(GITREPO) ShinobiSource
	cp ./Dockerfile.ponte124 ./ShinobiSource/
	cp ./.dockerignore ./ShinobiSource/
	docker buildx build --no-cache --platform linux/amd64,linux/arm64 -t $(NS)/$(IMAGE_NAME):$(VERSION) -t $(NS)/$(IMAGE_NAME):latest -f Dockerfile.ponte124 --progress=plain ${PWD}/ShinobiSource

push:
	docker push $(NS)/$(IMAGE_NAME):$(VERSION) $(NS)/$(IMAGE_NAME):latest
