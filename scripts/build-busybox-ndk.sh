#!/usr/bin/env bash
set -euo pipefail

# Build busybox statically using Android NDK clang for given arch.
# Usage: build-busybox-ndk.sh <arch> <ndk-root> <output-dir>
# arch: aarch64 | x86_64

ARCH="$1"
NDK_ROOT="$2"
OUTDIR="$3"

case "$ARCH" in
  aarch64)
    TARGET_HOST=aarch64-linux-android
    API=21
    ;;
  x86_64)
    TARGET_HOST=x86_64-linux-android
    API=21
    ;;
  *) echo "Unsupported arch"; exit 1;;
esac

mkdir -p "$OUTDIR"
echo "Building busybox for $ARCH using NDK at $NDK_ROOT"

# assume busybox source is available or download a release
BUSYBOX_VERSION=1.36.1
WORK=$(mktemp -d)
cd "$WORK"
wget -q https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
tar xjf busybox-${BUSYBOX_VERSION}.tar.bz2
cd busybox-${BUSYBOX_VERSION}

export PATH="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
if [ "$ARCH" = "aarch64" ]; then
  CC=aarch64-linux-android${API}-clang
else
  CC=x86_64-linux-android${API}-clang
fi

make defconfig
sed -i 's/.*CONFIG_STATIC.*/CONFIG_STATIC=y/' .config || true
make -j$(nproc) CC=$CC
cp busybox "$OUTDIR/busybox-$ARCH"
strip "$OUTDIR/busybox-$ARCH" || true
echo "Busybox built at $OUTDIR/busybox-$ARCH"

rm -rf "$WORK"
