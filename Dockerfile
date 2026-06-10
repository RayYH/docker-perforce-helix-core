# Perforce Helix Core (p4d) on Ubuntu
FROM ubuntu:22.04

LABEL maintainer="rayyh <rayyounghong@gmail.com>"

ARG GOSU_VERSION=1.17

ENV DEBIAN_FRONTEND=noninteractive \
    P4PORT=1666 \
    P4ROOT=/perforce/metadata \
    P4LOG=/perforce/logs/p4d.log \
    P4JOURNAL=/perforce/logs/journal \
    P4SERVERID=master.1

# Install Perforce, gosu, and runtime utilities in a single layer.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg tzdata vim-tiny; \
    curl -fsSL https://package.perforce.com/perforce.pubkey \
        | gpg --dearmor -o /usr/share/keyrings/perforce-archive-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/perforce-archive-keyring.gpg] http://package.perforce.com/apt/ubuntu jammy release" \
        > /etc/apt/sources.list.d/perforce.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends helix-p4d helix-cli; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${arch}" \
        -o /usr/local/sbin/gosu; \
    chmod +x /usr/local/sbin/gosu; \
    /usr/local/sbin/gosu --version; \
    id -u perforce >/dev/null 2>&1 || useradd -r -u 1001 -g root -m -d /home/perforce perforce; \
    mkdir -p /perforce/metadata /perforce/logs; \
    chown -R perforce:root /perforce; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 entrypoint.sh /usr/local/bin/start-p4d

VOLUME ["/perforce"]
EXPOSE 1666

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD p4 -p "localhost:${P4PORT}" info >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/start-p4d"]
