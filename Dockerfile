# Perforce Helix Core (p4d) on Ubuntu
FROM ubuntu:22.04

LABEL maintainer="rayyh <rayyounghong@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV P4PORT=1666 \
    P4ROOT=/perforce/metadata \
    P4LOG=/perforce/logs/p4d.log \
    P4JOURNAL=/perforce/logs/journal \
    P4SERVERID=master.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg tzdata \
    && curl -fsSL https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /usr/share/keyrings/perforce-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/perforce-archive-keyring.gpg] http://package.perforce.com/apt/ubuntu jammy release" \
    > /etc/apt/sources.list.d/perforce.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    helix-p4d helix-cli \
    && rm -rf /var/lib/apt/lists/*

# Non-root user
RUN id -u perforce >/dev/null 2>&1 || useradd -r -u 1001 -g root -m -d /home/perforce perforce

# Data dirs (bind/volume these on run)
RUN mkdir -p /perforce/metadata /perforce/logs \
    && chown -R perforce:root /perforce

VOLUME ["/perforce"]
EXPOSE 1666

# gosu for clean UID switch
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-$arch" -o /usr/local/sbin/gosu; \
    chmod +x /usr/local/sbin/gosu; \
    /usr/local/sbin/gosu --version

# Entry point: first-run init + start p4d in foreground
RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    '' \
    ': "${P4ROOT:?}" "${P4LOG:?}" "${P4JOURNAL:?}" "${P4PORT:?}" "${P4SERVERID:?}"' \
    'mkdir -p "$(dirname "$P4LOG")" "$P4ROOT"' \
    'chown -R perforce:root /perforce' \
    '' \
    '# first-run init if no database files exist' \
    'if [ ! -f "$P4ROOT/db.counters" ]; then' \
    '  echo ">> First run: initializing Perforce db under $P4ROOT"' \
    '  # initialize metadata (creates core db.* files if missing)' \
    '  exec 3>&1' \
    '  /usr/local/sbin/gosu perforce p4d -r "$P4ROOT" -xi >&3' \
    'fi' \
    '' \
    '# ensure server.id exists' \
    'if [ ! -f "$P4ROOT/server.id" ]; then' \
    '  echo "$P4SERVERID" > "$P4ROOT/server.id"' \
    '  chown perforce:root "$P4ROOT/server.id"' \
    '  echo ">> Wrote server.id = $P4SERVERID"' \
    'fi' \
    '' \
    'echo ">> Starting p4d on 0.0.0.0:${P4PORT}"' \
    'exec /usr/local/sbin/gosu perforce p4d \\' \
    '  -r "$P4ROOT" \\' \
    '  -L "$P4LOG" \\' \
    '  -J "$P4JOURNAL" \\' \
    '  -p "0.0.0.0:$P4PORT" \\' \
    '  -v server=3' \
    > /usr/local/bin/start-p4d && chmod +x /usr/local/bin/start-p4d

# tiny editor if you want
RUN apt-get update && apt-get install -y --no-install-recommends vim-tiny \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/local/bin/start-p4d"]