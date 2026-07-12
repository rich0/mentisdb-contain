# mentisdb-contain

Container image packaging for [MentisDB](https://github.com/CloudLLM-ai/mentisdb).

This repository only builds and publishes a Docker image from upstream MentisDB
release binaries. It is **not** affiliated with the MentisDB authors or
CloudLLM-ai.

## Image

- Registry: `registry.rich0.org/public/mentisdb` (Zot, public anonymous pull)
- Version pin: `VERSION` file (passed as `MENTISDB_VERSION` build-arg)
- Base: `ubuntu:24.04` (matches upstream glibc)
- Ports: `9471` (MCP), `9472` (REST), `9473`–`9474`, `9475` (dashboard)
- Data: volume `/data`

### Pull

```bash
docker pull registry.rich0.org/public/mentisdb:latest
# or pin a version
docker pull registry.rich0.org/public/mentisdb:0.10.4.49
```

Public pulls do not require login.

## Build and publish

```bash
docker login registry.rich0.org -u ci-push -p '<password>'
./build-push.sh
```

Pins `MENTISDB_VERSION` from `VERSION` and publishes to
`registry.rich0.org/public/mentisdb` (`:<version>` and `:latest`). Override with
`IMAGE=...` or `MENTISDB_VERSION=...` if needed.
