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