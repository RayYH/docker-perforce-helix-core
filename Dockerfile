# Perforce Helix Core (p4d) on Ubuntu
FROM ubuntu:22.04

LABEL maintainer="rayyh <rayyounghong@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV P4PORT=1666 \
    P4ROOT=/perforce/metadata \
    P4LOG=/perforce/logs/p4d.log \
    P4JOURNAL=/perforce/logs/journal

# Base tools + Perforce APT repo + p4d + CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release tzdata \
  && curl -fsSL https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /usr/share/keyrings/perforce-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/perforce-archive-keyring.gpg] http://package.perforce.com/apt/ubuntu $(lsb_release -cs) release" \
     > /etc/apt/sources.list.d/perforce.list \
  && apt-get update && apt-get install -y --no-install-recommends \
      helix-p4d helix-cli \
  && apt-get purge -y gnupg lsb-release \
  && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN id -u perforce >/dev/null 2>&1 || useradd -r -u 1001 -g root -m -d /home/perforce perforce

# Data dirs (bind/volume these on run)
RUN mkdir -p /perforce/metadata /perforce/logs \
  && chown -R perforce:root /perforce

VOLUME ["/perforce"]
EXPOSE 1666

# Minimal entrypoint: init dirs and run p4d in foreground
# You can extend this to auto-create a super user if you want.
RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'mkdir -p "$(dirname "$P4LOG")" "$P4ROOT"' \
    'chown -R perforce:root /perforce' \
    'exec gosu perforce p4d -r "$P4ROOT" -L "$P4LOG" -J "$P4JOURNAL" -p "0.0.0.0:$P4PORT" -v server=3 -f' \
    > /usr/local/bin/start-p4d && chmod +x /usr/local/bin/start-p4d

# gosu for clean UID switch (tiny, no suid weirdness)
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-$arch" -o /usr/local/sbin/gosu; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-$arch.asc" -o /tmp/gosu.asc; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || true; \
    gpg --batch --verify /tmp/gosu.asc /usr/local/sbin/gosu || true; \
    rm -rf "$GNUPGHOME" /tmp/gosu.asc; \
    chmod +x /usr/local/sbin/gosu; \
    gosu --version

# install vim
RUN apt-get update && apt-get install -y --no-install-recommends \
      vim-tiny \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/start-p4d"]
