# Docker - Shinobi

Docker image of Shinobi Video

## References

- Main source repo: <https://gitlab.com/Shinobi-Systems/Shinobi.git>
- Official dockerfile: 
    - Integrated: <https://gitlab.com/Shinobi-Systems/Shinobi/-/tree/master/Docker>
    - "Production": <https://gitlab.com/Shinobi-Systems/ShinobiDocker/-/blob/master/Dockerfile>

I hope they take my work, improve it and include it inside official repo.

## Features. Why I built this image

I want an image for my home kubernetes cluster (mix of raspberry, rock64, celeron)
- multiarch (at least arm64, x86)
    - See Makefile ... using buildx
- more docker friendly:
    - with few layers, commands aggregation
    - more docker-cache-friendly
- newer base versions (less vulnerabilities, more fixes, better performance)
    - Using node 25 (official still in 22)
    - Using debian 13 (ofricial still in 12)
- slim, or, at least, not so big
    - with no database server included (a bit more lightweight and clean, you can have your own separated mariadb server)
    - no git included (log warning, but i consider this optional)
    - pruning some useless files for runtime
- a bit less unsecure (without a bunch of libs and shell tools included)
    - Using for runtime dhi (still using "-dev" variant ... because of the mess with shell scripts). A bit bigger than trixie-slim, but only about 10M
    - no git included
- plugin included
    - mqtt (see init.sh)

## Warning and disclaimer

- This is not a optimum image.
- This is provided with no warranty at all.

## Supported architectures

ARM64, X86

## Where is the docker image

[ponte124/shinobi:latest](https://hub.docker.com/r/ponte124/shinobi)

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
        - Mariadb (container or native, as you prefer)
        - Configure some environment variables (look at docker-compose.yml here or <https://gitlab.com/Shinobi-Systems/Shinobi/-/tree/master/Docker#environment-variables>)

    `# docker run -it --rm --name shinobi --link <mariadb-container> -e <ENV>=<VALUE> ponte124/docker-shinobi:latest`

## Building or customizing the image

First clone this repo. Here there's an old-style simple Makefile:

`# make buildx`

## To Do

I'll do it when I have some time... but if you have time... help is welcome

- dhi image (without "-dev" variant; fixing shell mess)
- prune more files (eg: /home/Shinobi/INSTALL)
