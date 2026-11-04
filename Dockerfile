# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

# Upstream release binaries are linked against glibc 2.43.
# libm symbols (remainderf, asinf, acosf, sinhf, coshf, acoshf, atanhf) are
# versioned GLIBC_2.43. Ubuntu 24.04 ships glibc 2.39 and the dynamic linker
# refuses to start those binaries. Ubuntu 26.04 ships glibc 2.43.
FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c AS fetch

ARG TARGETARCH

# Package versions are pinned so Renovate can track them. Suites are in renovate.json.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates=20260816ubuntu0.26.04.1 \
        curl=8.18.0-1ubuntu2.8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

COPY VERSION /tmp/VERSION

RUN set -eux; \
    release="$(tr -d '[:space:]' < /tmp/VERSION)"; \
    if [ -z "${release}" ]; then \
      echo "error: VERSION is empty" >&2; \
      exit 1; \
    fi; \
    case "${TARGETARCH}" in \
      amd64) ARCH="x86_64" ;; \
      arm64) ARCH="arm64" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    URL="https://github.com/CloudLLM-ai/mentisdb/releases/download/${release}/mentisdb-linux-${ARCH}"; \
    curl -fsSL -o mentisdb "${URL}"; \
    chmod +x mentisdb; \
    rm -f /tmp/VERSION

FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

LABEL org.opencontainers.image.authors="Richard Freeman <rich@rich0.org>"
LABEL org.opencontainers.image.source=https://github.com/rich0/mentisdb-contain

ENV DEBIAN_FRONTEND=noninteractive

# Package versions are pinned so Renovate can track them. Suites are in renovate.json.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates=20260816ubuntu0.26.04.1 \
        curl=8.18.0-1ubuntu2.8 \
        libasound2t64=1.2.15.3-1ubuntu1.1 \
        tini=0.19.0-6 \
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
