#!/usr/bin/env bash
set -euo pipefail

# Cross-build proot for Android using NDK.
# Usage: build-proot-ndk.sh <arch> <ndk-root> <output-dir>

ARCH="$1"
NDK_ROOT="$2"
OUTDIR="$3"

case "$ARCH" in
  aarch64)
    API=21
    TARGET=aarch64-linux-android
    ;;
  x86_64)
    API=21
    TARGET=x86_64-linux-android
    ;;
  *) echo "Unsupported arch"; exit 1;;
esac

mkdir -p "$OUTDIR"
echo "Building proot for $ARCH using NDK at $NDK_ROOT"

WORK=$(mktemp -d)
cd "$WORK"
git clone https://github.com/proot-me/proot.git
cd proot

SYSROOT="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
export PATH="$TOOLCHAIN:$PATH"
CC="${TARGET}${API}-clang"
CXX="${TARGET}${API}-clang++"
AR="llvm-ar"
RANLIB="llvm-ranlib"
STRIP="llvm-strip"
CPPFLAGS="--sysroot=$SYSROOT"
CFLAGS="--sysroot=$SYSROOT -D__ANDROID_API__=$API -fPIE -fPIC"
CXXFLAGS="$CFLAGS"
LDFLAGS="--sysroot=$SYSROOT -pie"
export CC CXX AR RANLIB STRIP CPPFLAGS CFLAGS CXXFLAGS LDFLAGS

if [ ! -x "./configure" ]; then
  if [ -x "./autogen.sh" ]; then
    ./autogen.sh
  fi
fi

set +e
CC="$CC" CXX="$CXX" CPPFLAGS="$CPPFLAGS" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" ./configure --host=$TARGET --disable-shared --enable-static --prefix=/usr
CONFIG_STATUS=$?
set -e
if [ $CONFIG_STATUS -ne 0 ]; then
  echo "Configure failed with status $CONFIG_STATUS" >&2
fi

make -j$(nproc) CC="$CC" CXX="$CXX" AR="$AR" RANLIB="$RANLIB" STRIP="$STRIP" || true
if [ -f proot ]; then
  cp proot "$OUTDIR/proot-$ARCH"
  "$STRIP" "$OUTDIR/proot-$ARCH" || true
  chmod +x "$OUTDIR/proot-$ARCH"
  echo "proot built at $OUTDIR/proot-$ARCH"
else
  echo "proot build failed; no binary produced" >&2
fi

rm -rf "$WORK"
