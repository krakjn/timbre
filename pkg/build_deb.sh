#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <architecture>"
    echo "Example: $0 amd64"
    exit 1
fi

ARCH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/version.txt")"
PKG_DIR="out/pkg/$ARCH"

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

if [ -f "out/$TRIPLE/bin/timbre" ]; then
    cp "out/$TRIPLE/bin/timbre" "$PKG_DIR/usr/bin/"
else
    echo "Error: No binary found for $TRIPLE"
    exit 1
fi

chmod +x "$PKG_DIR/usr/bin/timbre"
dpkg-deb --build --root-owner-group "$PKG_DIR" "out/pkg/timbre-${VERSION}-${ARCH}.deb"
echo "Package created: out/pkg/timbre-${VERSION}-${ARCH}.deb" 