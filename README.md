# `docker-perforce-helix-core`

`docker-perforce-helix-core` is a Docker image for running Perforce Helix Core
Server. Multi-arch: `linux/amd64`, `linux/arm64`.

```shell
mkdir -p ./perforce
docker run -d --name p4d \
  -p 1666:1666 \
  -e P4PORT=1666 \
  -v "$(pwd)/perforce:/perforce" \
  rayyounghong/perforce-helix-core:latest
```

The container runs `p4d` as the non-root `perforce` user. On first start it
initializes the database under `P4ROOT` and writes `server.id` if missing.

## Docker Compose

```yaml
services:
  p4d:
    image: rayyounghong/perforce-helix-core:latest
    container_name: p4d
    ports:
      - "1666:1666"
    environment:
      - P4PORT=1666
    volumes:
      - ./perforce:/perforce
    restart: unless-stopped
```

## Environment variables

| Variable     | Default                  | Purpose                      |
| ------------ | ------------------------ | ---------------------------- |
| `P4PORT`     | `1666`                   | Port `p4d` listens on        |
| `P4ROOT`     | `/perforce/metadata`     | Server metadata directory    |
| `P4LOG`      | `/perforce/logs/p4d.log` | Server log file              |
| `P4JOURNAL`  | `/perforce/logs/journal` | Journal file                 |
| `P4SERVERID` | `master.1`               | Value written to `server.id` |

## Volumes

`/perforce` holds all server state (`metadata/` and `logs/`). Mount it as a
named volume or bind mount to persist data across container restarts.

## Healthcheck

The image ships a healthcheck that runs `p4 -p localhost:$P4PORT info` every
30 seconds. Use `docker ps` or `docker inspect` to see the health status.
