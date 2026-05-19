#!/usr/bin/env bash
# Cross-compile helper for building userland for arm64 and x86_64 using Android NDK clang
# Usage: ./cross-compile-toolchain.sh <arch> <api-level> <source.c>

set -euo pipefail

ARCH="$1" # aarch64|x86_64
API=${2:-21}
SRC=${3:-}

if [ -z "$SRC" ]; then
  echo "Usage: $0 <aarch64|x86_64> <api> <source.c>"
  exit 1
fi

NDK_ROOT=${NDK_ROOT:-$HOME/Android/Sdk/ndk/23.1.7779620}
if [ ! -d "$NDK_ROOT" ]; then
  echo "Set NDK_ROOT to a valid Android NDK path" >&2
  exit 1
fi

case "$ARCH" in
  aarch64)
    TARGET=aarch64-linux-android
    CROSS_PREFIX=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-
    ;;
  x86_64)
    TARGET=x86_64-linux-android
    CROSS_PREFIX=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${API}-
    ;;
  *) echo "Unsupported arch"; exit 1;;
esac

CC=${CROSS_PREFIX}clang
LD=${CROSS_PREFIX}ld

echo "Using CC=$CC"

"$CC" -o out.bin "$SRC"
echo "Built out.bin for $ARCH"
