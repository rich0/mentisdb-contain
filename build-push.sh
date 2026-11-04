#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

IMAGE="${IMAGE:-registry.rich0.org/public/mentisdb}"
PLATFORMS="${PLATFORMS:-linux/amd64}"
NO_CACHE="${NO_CACHE:-1}"

if [[ ! -f VERSION ]]; then
  echo "error: VERSION is missing" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < VERSION)"
if [[ -z "${VERSION}" ]]; then
  echo "error: VERSION is empty" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed or not on PATH" >&2
  exit 1
fi

BUILD_ARGS=(--pull)
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
    echo "error: push failed — run: docker login registry.rich0.org" >&2
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
  echo "(digest unavailable; re-run after push or inspect on registry.rich0.org)"
fi
