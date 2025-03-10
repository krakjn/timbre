ARG ARCH=x86_64
FROM ubuntu:22.04 as builder

RUN <<EOF
apt-get update
apt-get install -y \
    build-essential \
    cmake \
    git \
    ninja-build \
    pkg-config \
    crossbuild-essential-arm64
rm -rf /var/lib/apt/lists/*
EOF

WORKDIR /app
COPY . .

ARG ARCH
RUN /bin/bash <<EOF
set -e
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_${ARCH:-x86_64}.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)
EOF

FROM ubuntu:22.04

RUN <<EOF
apt-get update
apt-get install -y libstdc++6
rm -rf /var/lib/apt/lists/*
mkdir -p /etc/timbre /var/log/timbre
EOF


COPY --from=builder /app/build/${ARCH:-x86_64}/Release/timbre /usr/local/bin/timbre
COPY cfg/timbre.toml /etc/timbre/config.toml

# Set up a non-root user
RUN useradd -ms /bin/bash timbre && \
    chown -R timbre:timbre /var/log/timbre /etc/timbre

USER timbre
WORKDIR /home/timbre

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD [ "timbre", "--version" ]

ENTRYPOINT ["timbre"]
CMD ["--config", "/etc/timbre/config.toml"] 