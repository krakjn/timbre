FROM ubuntu:22.04 AS builder
ARG ARCH=x86_64

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

RUN set -e && \
    cmake -B build/${ARCH} -S . -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_${ARCH}.cmake && \
    cmake --build build/${ARCH} -j

FROM ubuntu:22.04
ARG ARCH=x86_64

RUN <<EOF
apt-get update
apt-get install -y libstdc++6
rm -rf /var/lib/apt/lists/*
mkdir -p /etc/timbre /var/log/timbre
EOF

COPY --from=builder /app/build/${ARCH}/timbre /usr/local/bin/timbre
COPY cfg/timbre.toml /etc/timbre/config.toml

# Set up a non-root user
RUN useradd -ms /bin/bash timbre && \
    chown -R timbre:timbre /var/log/timbre /etc/timbre

USER timbre
WORKDIR /home/timbre

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD [ "timbre", "--version" ]

CMD ["/bin/bash"] 