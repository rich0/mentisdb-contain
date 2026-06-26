#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

IMAGE="${IMAGE:-ghcr.io/rich0/mentisdb}"
VERSION="${MENTISDB_VERSION:-$(tr -d '[:space:]' < VERSION)}"
PLATFORMS="${PLATFORMS:-linux/amd64}"
NO_CACHE="${NO_CACHE:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed or not on PATH" >&2
  exit 1
fi

if [[ -z "${VERSION}" ]]; then
  echo "error: VERSION file is empty and MENTISDB_VERSION is unset" >&2
  exit 1
fi

BUILD_ARGS=(--pull --build-arg "MENTISDB_VERSION=${VERSION}")
if [[ "${NO_CACHE}" == "1" ]]; then
  BUILD_ARGS+=(--no-cache)
fi

TAG_VERSION="${IMAGE}:${VERSION}"
TAG_LATEST="${IMAGE}:latest"

echo "Building ${TAG_VERSION} (platforms: ${PLATFORMS})"

if [[ "${PLATFORMS}" == *","* ]]; then
  docker buildx build "${BUILD_ARGS[@]}" \
    --platform "${PLATFORMS}" \
    --tag "${TAG_VERSION}" \
    --tag "${TAG_LATEST}" \
    --push \
    .
else
  docker build "${BUILD_ARGS[@]}" \
    --tag "${TAG_VERSION}" \
    --tag "${TAG_LATEST}" \
    .

  echo "Pushing ${TAG_VERSION}"
  if ! docker push "${TAG_VERSION}"; then
    echo "error: push failed — run: docker login ghcr.io" >&2
    exit 1
  fi

  echo "Pushing ${TAG_LATEST}"
  docker push "${TAG_LATEST}"
fi

echo
echo "Flux image pin:"
DIGEST=""
if docker buildx imagetools inspect "${TAG_VERSION}" --format '{{.Manifest.Digest}}' >/dev/null 2>&1; then
  DIGEST="$(docker buildx imagetools inspect "${TAG_VERSION}" --format '{{.Manifest.Digest}}')"
elif REPO_DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "${TAG_VERSION}" 2>/dev/null || true)" \
  && [[ -n "${REPO_DIGEST}" ]]; then
  echo "${REPO_DIGEST}"
  exit 0
fi

if [[ -n "${DIGEST}" ]]; then
  echo "${TAG_VERSION}@${DIGEST}"
else
  echo "${TAG_VERSION}"
  echo "(digest unavailable; re-run after push or inspect in ghcr.io)"
fi