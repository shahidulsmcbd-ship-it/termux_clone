#!/usr/bin/env bash
# Sketch: cross-compile PRoot using an Android NDK toolchain.

set -euo pipefail

NDK_ROOT=${NDK_ROOT:-$HOME/Android/Sdk/ndk/23.1.7779620}
if [ ! -d "$NDK_ROOT" ]; then
  echo "Set NDK_ROOT to a valid Android NDK path" >&2
  exit 1
fi

echo "This script outlines steps to build proot for Android cross-arch."
echo "Recommended: build proot natively on each target or use a cross-compile Docker container."

echo "Example: clone proot and use the NDK clang to build with appropriate CC/LDFLAGS."
