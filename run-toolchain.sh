#!/usr/bin/env bash
set -e

IMAGE_NAME=osdev-toolchain

# Build image if it doesn’t exist yet
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
	echo "[+] Building $IMAGE_NAME..."
	docker build -t "$IMAGE_NAME" .
fi

# Use the host path inside the container, and run as your user
docker run -it --rm \
	-v "$PWD":"$PWD" \
	-w "$PWD" \
	-u "$(id -u)":"$(id -g)" \
	-e HOME="$HOME" -e USER="$USER" \
	"$IMAGE_NAME" bash
