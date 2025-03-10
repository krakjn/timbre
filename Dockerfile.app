ARG ARCH=x86_64
FROM ubuntu:22.04 as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    ninja-build \
    pkg-config \
    crossbuild-essential-arm64 \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
WORKDIR /app
COPY . .

# Build Timbre
ARG ARCH
RUN if [ "$ARCH" = "arm64" ]; then \
        cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_arm64.cmake -DCMAKE_BUILD_TYPE=Release && \
        cmake --build build --config Release -j$(nproc); \
    else \
        cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_x86_64.cmake -DCMAKE_BUILD_TYPE=Release && \
        cmake --build build --config Release -j$(nproc); \
    fi

# Create a smaller runtime image
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Copy the built binary and config
ARG ARCH
COPY --from=builder /app/build/${ARCH}/Release/timbre /usr/local/bin/timbre
COPY cfg/timbre.toml /etc/timbre/config.toml

# Set up a non-root user
RUN useradd -ms /bin/bash timbre && \
    mkdir -p /var/log/timbre && \
    chown -R timbre:timbre /var/log/timbre /etc/timbre

USER timbre
WORKDIR /home/timbre

# Run the application
ENTRYPOINT ["timbre"]
CMD ["--config", "/etc/timbre/config.toml"] 