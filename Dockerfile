# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS fetch

ARG MENTISDB_VERSION=0.10.4.49
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Pinned SHA256 digests from CloudLLM-ai/mentisdb release assets.
# Update these when bumping MENTISDB_VERSION.
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) ARCH="x86_64"; SHA256="5dd92ce1f0e32b79d6a8d4327bcf9d85186bbbc95cb70e40402cd51d32a6333b" ;; \
      arm64) ARCH="arm64"; SHA256="bb33f3e86ce6ae6d09eb3974a075f8a4b461cdeffac5101d994f7dc9cde90e75" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    URL="https://github.com/CloudLLM-ai/mentisdb/releases/download/${MENTISDB_VERSION}/mentisdb-linux-${ARCH}"; \
    curl -fsSL -o mentisdb "${URL}"; \
    echo "${SHA256}  mentisdb" | sha256sum -c -; \
    chmod +x mentisdb

FROM debian:bookworm-slim

LABEL org.opencontainers.image.authors="Richard Freeman <rich@rich0.org>"
LABEL org.opencontainers.image.source=https://github.com/rich0/mentisdb-contain

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libasound2 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 1000 --home-dir /data --shell /usr/sbin/nologin mentisdb

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