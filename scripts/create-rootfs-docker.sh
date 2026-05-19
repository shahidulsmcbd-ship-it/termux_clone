#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <arch> <distro> <output-tar>

arch: arm64 | x86_64
distro: debian-bullseye | debian-bookworm (example)
output-tar: path to produced tar.gz

Example:
  ./create-rootfs-docker.sh arm64 debian-bullseye rootfs-arm64.tar.gz
EOF
}

if [ "$#" -ne 3 ]; then
  usage
  exit 1
fi

ARCH_IN="$1"
DISTRO_RAW="$2"
OUT_TAR="$3"

case "$ARCH_IN" in
  arm64) DEBOOTSTRAP_ARCH=arm64 ;;
  x86_64) DEBOOTSTRAP_ARCH=amd64 ;;
  *) echo "Unsupported arch: $ARCH_IN" >&2; exit 1 ;;
esac

case "$DISTRO_RAW" in
  debian-bullseye) DISTRO=bullseye ;;
  debian-bookworm) DISTRO=bookworm ;;
  *) DISTRO=$DISTRO_RAW ;;
esac

WORKDIR=$(pwd)/build-rootfs
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"


echo "Running debootstrap in container for arch=$DEBOOTSTRAP_ARCH distro=$DISTRO"
# Assumes qemu user static is registered on the host (CI should register it via docker/setup-qemu-action)

docker run --rm -v "$WORKDIR":/work debian:stable-slim bash -c "\
  set -e; apt-get update && apt-get install -y debootstrap wget ca-certificates qemu-user-static && \
  debootstrap --arch=$DEBOOTSTRAP_ARCH $DISTRO /work/rootfs http://deb.debian.org/debian && \
  # install proot and busybox inside the rootfs
  chroot /work/rootfs /bin/bash -c 'apt-get update && apt-get install -y --no-install-recommends proot busybox-static && apt-get clean' || true && \
  mkdir -p /work/artifacts && \
  # copy userland binaries out for separate packaging (if present)
  if [ -f /work/rootfs/usr/bin/proot ]; then cp /work/rootfs/usr/bin/proot /work/artifacts/proot-$(uname -m); fi && \
  if [ -f /work/rootfs/bin/busybox ]; then cp /work/rootfs/bin/busybox /work/artifacts/busybox-$(uname -m); fi && \
  tar -C /work/rootfs -czf /work/out-rootfs.tar.gz . && \
  tar -C /work/artifacts -czf /work/out-artifacts.tar.gz ."

mv "$WORKDIR/out-rootfs.tar.gz" "$OUT_TAR"
if [ -f "$WORKDIR/out-artifacts.tar.gz" ]; then mv "$WORKDIR/out-artifacts.tar.gz" "${OUT_TAR%.tar.gz}-artifacts.tar.gz"; fi
echo "Created $OUT_TAR"
