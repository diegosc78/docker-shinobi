# Docker - Shinobi

Docker image of Shinobi Video

## References

- Main source repo: <https://gitlab.com/Shinobi-Systems/Shinobi.git>
- Official dockerfile: <https://gitlab.com/Shinobi-Systems/Shinobi/-/tree/master/Docker>

I hope they take my work, improve it and include it inside official repo.

## Why I built this image

I want an image for my home kubernetes cluster (mix of raspberry, rock64, celeron)
- multiarch (at least arm64, x86)
- with few layers
- slim, or, at least, not so big
- with no database server included (I have my own separated mariadb server)
- a bit less unsecure (without a bunch of libs and shell tools included)

## Warning and disclaimer

- This is not a optimum image.
- This is provided with no warranty at all.

## Supported architectures

ARM64, X86

## Where is the docker image

[ponte124/shinoby:latest-arm64v8](https://hub.docker.com/r/ponte124/shinobi)

## What's inside

- Some system packages
- MySQL client
- Shinobi app (nodejs), exposing port 8080

## Basic usage

- **Docker-compose:** (recommended)
    - If you don't have docker-compose installed and you have ARM64... maybe you like <https://hub.docker.com/r/szcxo/docker-compose>
    - Download this repo (at least docker-compose.yml)
    - Check env variables inside provided docker-compose.yaml

    `# docker-compose up -d && docker-compose logs -f`

    - First time maybe it doesn't work because of db is not available yet. Just wait a bit and restart shinobi container

    `# docker-compose restart shinobi && docker-compose logs -f shinobi`

- **Docker command line:** 
    - First of all you'll need:
        - Mariadb (contairner or native, as you prefer)
        - Configure some environment variables (look at docker-compose.yml here or <https://gitlab.com/Shinobi-Systems/Shinobi/-/tree/master/Docker#environment-variables>)

    `# docker run -it --rm --name shinobi --link <mariadb-container> -e <ENV>=<VALUE> ponte124/docker-shinobi:latest-arm64v8`

## Building or customizing the image

First clone this repo. Here there's an old-style simple Makefile:

- **Build:**

    `# make build`

- **Push:** You'll need first to customize registry in Makefile and login your registry

    `# make push`

## To Do

I'll do it when I have some time... but if you have time... help is welcome

- Non-root user
