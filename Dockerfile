FROM ubuntu:22.04

# OCI Annotations
LABEL org.opencontainers.image.source="https://github.com/krakjn/timbre"

RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    apt-utils \
    ca-certificates \
    clang-format \
    clang-tidy \
    cppcheck \
    curl \
    debhelper \
    devscripts \
    dh-make \
    dpkg-dev \
    fakeroot \
    git \
    jq \
    pkg-config \
    tzdata \
    wget \
    xz-utils
# Clean up apt cache
rm -rf /var/lib/apt/lists/*
EOF

# Install Zig 0.14.0
RUN <<EOF
ZIG_VERSION="0.14.0"
cd /tmp
wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
tar -xf "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
mv "zig-linux-x86_64-${ZIG_VERSION}" /usr/local/zig
ln -s /usr/local/zig/zig /usr/local/bin/zig
rm "zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
zig version
EOF

RUN <<EOF
# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g @commitlint/cli @commitlint/config-conventional auto-changelog
EOF

WORKDIR /app
ENTRYPOINT ["/bin/bash"]
