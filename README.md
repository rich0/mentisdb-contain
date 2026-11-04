# mentisdb-contain

Container image packaging for [MentisDB](https://github.com/CloudLLM-ai/mentisdb).

This repository only builds and publishes a Docker image from upstream MentisDB
release binaries. It is **not** affiliated with the MentisDB authors or
CloudLLM-ai.

## Image

- Registry: `registry.rich0.org/public/mentisdb` (Zot, public anonymous pull)
- Version pin: `VERSION`. The image tag and the upstream binary both come from that file. The build fails if it is missing or empty.
- Base: `ubuntu:26.04` (glibc 2.43, required by the upstream binaries)
- Ports: `9471` (MCP), `9472` (REST), `9473`–`9474`, `9475` (dashboard)
- Data: volume `/data`

### Pull

```bash
docker pull registry.rich0.org/public/mentisdb:latest
```

Public pulls do not require login.

## Build and publish

```bash
docker login registry.rich0.org -u ci-push -p '<password>'
./build-push.sh
```

Reads `VERSION` and publishes to `registry.rich0.org/public/mentisdb`
(`:<version>` and `:latest`). Override the repository with `IMAGE=...` if needed.
