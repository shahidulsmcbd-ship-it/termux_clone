#!/usr/bin/env bash
set -euo pipefail

# Builds and packages rootfs tarballs for multiple architectures.
# Requires Docker and sufficient disk space.

ARCHES=(arm64 x86_64)
DISTRO=${1:-debian-bullseye}
OUTDIR=${2:-dist/rootfs}

mkdir -p "$OUTDIR"

for a in "${ARCHES[@]}"; do
  out="$OUTDIR/rootfs-${a}.tar.gz"
  echo "Building rootfs for $a -> $out"
  ./create-rootfs-docker.sh "$a" "$DISTRO" "$out"
  # move artifacts produced alongside rootfs
  if [ -f "${out%.tar.gz}-artifacts.tar.gz" ]; then
    mkdir -p "$OUTDIR/artifacts"
    mv "${out%.tar.gz}-artifacts.tar.gz" "$OUTDIR/artifacts/"
  fi
done

echo "All rootfs packages are in $OUTDIR"
