# `docker-perforce-helix-core`

`docker-perforce-helix-core` is a Docker image for running Perforce Helix Core Server.

```shell
mkdir -p ./perforce
docker run -d --name p4d \
  -p 1666:1666 \
  -e P4PORT=1666 \
  -v "$(pwd)/perforce:/perforce" \
  rayyounghong/perforce-helix-core:latest
```

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