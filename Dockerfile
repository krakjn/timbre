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
    cppcheck \
    crossbuild-essential-arm64 \
    curl \
    debhelper \
    devscripts \
    dh-make \
    dpkg-dev \
    fakeroot \
    g++ \
    git \
    jq \
    dpkg-cross \
    make \
    ninja-build \
    pkg-config \
    tzdata \
    wget
# Clean up apt cache
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g @commitlint/cli @commitlint/config-conventional auto-changelog

# Install Catch2 for amd64
cd /opt
git clone https://github.com/catchorg/Catch2.git
cd Catch2
git checkout v3.8.0
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --target install -j$(nproc)

# NOTE: Due to cross-compilation, we are not installing Catch2 for arm64.
#       Arm runtime with qemu is needed to run tests.
#       Manually creating symlinks from /usr/lib/aarch64-linux-gnu/
#       to /lib is probably the best solution.

rm -rf Catch2
EOF
