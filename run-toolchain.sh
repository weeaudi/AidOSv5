#!/usr/bin/env bash
# Builds (if needed) and runs your OSDev toolchain container interactively.

set -e

IMAGE_NAME=osdev-toolchain

# Build image if it doesn’t exist yet
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "[+] Building $IMAGE_NAME..."
  docker build -t $IMAGE_NAME .
fi

# Run container with current dir mounted
docker run -it --rm \
  -v "$PWD":/work \
  -w /work \
  $IMAGE_NAME bash
