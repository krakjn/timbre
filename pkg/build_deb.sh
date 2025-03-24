#!/bin/bash
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <architecture> <version>"
    echo "Example: $0 amd64 1.0.0"
    exit 1
fi

ARCH="$1"
VERSION="$2"
PKG_DIR="zig-out/pkg/$ARCH"

echo "ARCH: $ARCH"
echo "VERSION: $VERSION"
echo "PKG_DIR: $PKG_DIR"

echo "Building package for $ARCH with version $VERSION"

mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/doc/timbre"

cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: timbre
Version: $VERSION
Architecture: $ARCH
Maintainer: Tony B <krakjn@gmail.com>
Depends: libc6, libstdc++6
Section: utils
Priority: optional
Homepage: https://github.com/krakjn/timbre
Description: A modern C++ logging utility
 A modern, efficient, and flexible logging utility for C++ applications. It provides a clean command-line interface for structured logging with support for multiple output formats and destinations.
EOF

if [ "$ARCH" = "amd64" ]; then
    TRIPLE="x86_64-linux-musl"
elif [ "$ARCH" = "arm64" ]; then
    TRIPLE="aarch64-linux-musl"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

if [ -f "zig-out/$TRIPLE/timbre" ]; then
    cp "zig-out/$TRIPLE/timbre" "$PKG_DIR/usr/bin/"
else
    echo "Error: No binary found for $TRIPLE"
    exit 1
fi

dpkg-deb --build --root-owner-group "$PKG_DIR" "zig-out/pkg/timbre-${VERSION}-${ARCH}.deb"
echo "Package created: zig-out/$TRIPLE/pkg/timbre-${VERSION}-${ARCH}.deb" 