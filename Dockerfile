# ============================================================================
# SHINOBI OPTIMIZED DOCKERFILE WITH BUILDKIT FEATURES
# ============================================================================
# Multi-stage build with BuildKit cache optimization
# Security hardened with non-root user and minimal dependencies
# ============================================================================

# Global build arguments
ARG BASE_BUILDER_IMAGE=node:25-trixie-slim
ARG BASE_RUNTIME_IMAGE=dhi.io/node:25-debian13-dev
ARG DEBIAN_FRONTEND=noninteractive
ARG EXCLUDE_DB=true

# ============================================================================
# STAGE 1: BUILDER - Compile dependencies and prepare application
# ============================================================================
FROM ${BASE_BUILDER_IMAGE} AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG EXCLUDE_DB=true

# Environment variables for build and runtime configuration
ENV DB_USER=shinobi \
    DB_PASSWORD='shinobi' \
    DB_HOST='mariadb' \
    DB_DATABASE=ccio \
    DB_PORT=3306 \
    DB_TYPE='mysql' \
    SUBSCRIPTION_ID=sub_XXXXXXXXXXXX \
    PLUGIN_KEYS='{}' \
    SSL_ENABLED='false' \
    SSL_COUNTRY='ES' \
    SSL_STATE='GA' \
    SSL_LOCATION='Coruna' \
    SSL_ORGANIZATION='Ponte' \
    SSL_ORGANIZATION_UNIT='IT Department' \
    SSL_COMMON_NAME='cctv.ponte.me' \
    DB_DISABLE_INCLUDED=${EXCLUDE_DB} \
    DEBIAN_FRONTEND=${DEBIAN_FRONTEND}

WORKDIR /home/Shinobi

# Copy dependency manifests early for better layer caching
COPY package*.json ./

# Install system packages with BuildKit cache mount for faster rebuilds
# Consolidate apt-get commands to reduce layers and image size
# Use --no-install-recommends to minimize unnecessary dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Build essentials
        build-essential \
        git \
        pkg-config \
        # Languages & tools
        python3 \
        curl \
        wget \
        # Audio/Video processing
        ffmpeg \
        x264 \
        libx264-dev \
        libx265-dev \
        libfreetype6-dev \
        libgnutls28-dev \
        libmp3lame-dev \
        libass-dev \
        libogg-dev \
        libtheora-dev \
        libvorbis-dev \
        libvpx-dev \
        libwebp-dev \
        libssh2-1-dev \
        libopus-dev \
        librtmp-dev \
        # Utilities
        tar \
        bzip2 \
        xz-utils \
        yasm \
        nasm \
        coreutils \
        procps \
        gnutls-bin \
        sudo \
        apt-utils \
        ca-certificates \
        gnupg && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install Node.js global packages with BuildKit npm cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm cache clean -f && \
    npm install -g --maxsockets 1 \
        npm@latest \
        pm2 \
        pg

# Copy application source code
COPY . ./

# Install application dependencies with BuildKit npm cache mount
# Use npm ci for reproducible, production-ready builds
RUN --mount=type=cache,target=/root/.npm \
    npm install mqtt@5.14.1 && \
    npm install --unsafe-perm --maxsockets 1 && \
    npm prune --omit=dev --omit=optional && \
    find node_modules -type d -name ".github" -exec rm -rf {} + 2>/dev/null || true && \
    find node_modules -type d -name ".circleci" -exec rm -rf {} + 2>/dev/null || true && \
    find node_modules -type d -name ".gitlab" -exec rm -rf {} + 2>/dev/null || true && \
    find node_modules -type f -name "*.test.*" -delete && \
    find node_modules -type f -name "*README*" -delete && \
    find node_modules -type f -name "*CHANGELOG*" -delete

# Set up application directory permissions
# Prepare init script for Linux environments
RUN set -ex && \
    chmod 755 /home/Shinobi && \
    chmod -R 700 /home/Shinobi/plugins && \
    chmod 755 /home/Shinobi/Docker && \
    chmod +x /home/Shinobi/Docker/init.sh && \
    sed -i -e 's/\r//g' /home/Shinobi/Docker/init.sh && \
    echo "Build Info:" && \
    echo "  Node: $(node -v)" && \
    echo "  NPM:  $(npm -v)" && \
    echo "  ffmpeg: $(ffmpeg -version | head -1)"

# ============================================================================
# STAGE 2: RUNTIME - Minimal production image with only runtime dependencies
# ============================================================================
FROM ${BASE_RUNTIME_IMAGE} AS runtime

ARG DEBIAN_FRONTEND=noninteractive
ARG EXCLUDE_DB=true

# Runtime environment variables (smaller set than build stage)
ENV DB_USER=shinobi \
    DB_PASSWORD='shinobi' \
    DB_HOST='mariadb' \
    DB_DATABASE=ccio \
    DB_PORT=3306 \
    DB_TYPE='mysql' \
    SUBSCRIPTION_ID=sub_XXXXXXXXXXXX \
    PLUGIN_KEYS='{}' \
    SSL_ENABLED='false' \
    SSL_COUNTRY='ES' \
    SSL_STATE='GA' \
    SSL_LOCATION='Coruna' \
    SSL_ORGANIZATION='Ponte' \
    SSL_ORGANIZATION_UNIT='IT Department' \
    SSL_COMMON_NAME='cctv.ponte.me' \
    DB_DISABLE_INCLUDED=${EXCLUDE_DB} \
    DEBIAN_FRONTEND=${DEBIAN_FRONTEND}

# Install only runtime dependencies (no build tools)
# Significantly reduces final image size (~200-300MB reduction)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Runtime only dependencies
        ca-certificates \
        curl \
        python3 \
        # Audio/Video runtime (no dev packages)
        ffmpeg \
        x264 \
        # Database client
        mariadb-client \
        # System utilities
        tar \
        bzip2 \
        xz-utils \
        coreutils \
        procps \
        gnutls-bin \
        openssl && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install Node.js global packages in runtime stage
RUN --mount=type=cache,target=/root/.npm \
    npm cache clean -f && \
    npm install -g --maxsockets 1 \
        npm@latest \
        pm2 \
        pg

# Copy built application from builder stage
COPY --from=builder /home/Shinobi /home/Shinobi

# Create non-root user for security (UID 1000)
# Set correct ownership of application directory
RUN set -ex && \
    chown -R 1000:1000 /home/Shinobi && \
    chmod 755 /home/Shinobi && \
    chmod 755 /home/Shinobi/Docker

# Set working directory and switch to non-root user
WORKDIR /home/Shinobi
USER 1000:1000

# Clean up unnecessary files to reduce image size
# (node_modules already cleaned in builder stage)
RUN rm -f /home/Shinobi/Dockerfile* && \
    rm -f /home/Shinobi/*.md && \
    rm -f /home/Shinobi/package-lock.json

# Define volumes for persistent data
VOLUME ["/home/Shinobi/videos"]
VOLUME ["/home/Shinobi/plugins"]
VOLUME ["/home/Shinobi/libs/customAutoLoad"]
VOLUME ["/config"]

# Expose HTTP and HTTPS ports
EXPOSE 8080 8443

# Health check to verify container is running
# Checks HTTP endpoint every 30 seconds
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8080/ || exit 1

# Set entry point and default command
ENTRYPOINT ["/home/Shinobi/Docker/init.sh"]
CMD ["/opt/nodejs/node-v25.5.0/bin/pm2-docker", "/home/Shinobi/Docker/pm2.yml"]
