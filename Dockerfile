# Perforce Helix Core (p4d) on Ubuntu — multi-arch (amd64, arm64)
FROM ubuntu:22.04

LABEL maintainer="rayyh <rayyounghong@gmail.com>"

ARG GOSU_VERSION=1.17
ARG P4_RELEASE=r26.1
# Provided automatically by BuildKit for multi-platform builds: amd64 | arm64
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    P4PORT=1666 \
    P4ROOT=/perforce/metadata \
    P4LOG=/perforce/logs/p4d.log \
    P4JOURNAL=/perforce/logs/journal \
    P4SERVERID=master.1

# Install runtime deps, p4/p4d binaries from Perforce FTP, and gosu — single layer.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl tzdata vim-tiny; \
    case "$TARGETARCH" in \
        amd64) p4arch="x86_64" ;; \
        arm64) p4arch="aarch64" ;; \
        *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    p4base="https://ftp.perforce.com/perforce/${P4_RELEASE}/bin.linux26${p4arch}"; \
    curl -fsSL "${p4base}/p4d" -o /usr/local/bin/p4d; \
    curl -fsSL "${p4base}/p4"  -o /usr/local/bin/p4; \
    chmod +x /usr/local/bin/p4d /usr/local/bin/p4; \
    P4ROOT=/tmp /usr/local/bin/p4d -V | head -3; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${TARGETARCH}" \
        -o /usr/local/sbin/gosu; \
    chmod +x /usr/local/sbin/gosu; \
    /usr/local/sbin/gosu --version; \
    useradd -r -u 1001 -g root -m -d /home/perforce perforce; \
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
