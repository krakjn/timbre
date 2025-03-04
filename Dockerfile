FROM ubuntu:22.04

# OCI Annotations
LABEL org.opencontainers.image.source="https://github.com/krakjn/timbre"

RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    build-essential \
    ca-certificates \
    clang-format \
    clang-tidy \
    cmake \
    curl \
    debhelper \
    devscripts \
    dh-make \
    dpkg-dev \
    fakeroot \
    g++ \
    git \
    libcurl4-openssl-dev \
    make \
    ninja-build \
    nodejs \
    npm \
    pkg-config \
    tzdata \
    wget

# Clean up apt cache
rm -rf /var/lib/apt/lists/*
EOF

# Install global npm packages
RUN npm install -g @commitlint/cli @commitlint/config-conventional auto-changelog

# Install Catch2 test framework
RUN <<EOF
cd /opt
git clone https://github.com/catchorg/Catch2.git
cd Catch2
git checkout v3.8.0
cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --target install -j$(nproc)
rm -rf /opt/Catch2
EOF
