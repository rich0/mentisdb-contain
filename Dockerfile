# syntax=docker/dockerfile:1

# Upstream release binaries are built on ubuntu-latest (glibc 2.39).
# Debian bookworm (glibc 2.36) cannot run them.
FROM ubuntu:24.04 AS fetch

ARG MENTISDB_VERSION=0.10.4.49
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) ARCH="x86_64" ;; \
      arm64) ARCH="arm64" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    URL="https://github.com/CloudLLM-ai/mentisdb/releases/download/${MENTISDB_VERSION}/mentisdb-linux-${ARCH}"; \
    curl -fsSL -o mentisdb "${URL}"; \
    chmod +x mentisdb

FROM ubuntu:24.04

LABEL org.opencontainers.image.authors="Richard Freeman <rich@rich0.org>"
LABEL org.opencontainers.image.source=https://github.com/rich0/mentisdb-contain

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libasound2t64 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && userdel -r ubuntu 2>/dev/null || userdel ubuntu \
    && useradd --uid 1000 --home-dir /data --shell /usr/sbin/nologin --no-create-home mentisdb \
    && mkdir -p /data \
    && chown mentisdb:mentisdb /data

COPY --from=fetch /tmp/mentisdb /usr/local/bin/mentisdb

ENV MENTISDB_DIR=/data \
    MENTISDB_BIND_HOST=0.0.0.0 \
    MENTISDB_AUTO_FLUSH=true \
    MENTISDB_UPDATE_CHECK=false \
    MENTISDB_STARTUP_SOUND=false \
    MENTISDB_DASHBOARD_PORT=9475 \
    RUST_LOG=info

VOLUME /data
WORKDIR /data

EXPOSE 9471/tcp 9472/tcp 9473/tcp 9474/tcp 9475/tcp

USER mentisdb

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -fsS http://127.0.0.1:9472/health || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["mentisdb", "--headless"]
