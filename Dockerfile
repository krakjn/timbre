FROM ubuntu:22.04

RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    tzdata \
    build-essential \
    cmake \
    git \
    g++ \
    make
rm -rf /var/lib/apt/lists/*
EOF

# WORKDIR /app

# # Copy source code
# COPY . .

# # Build the application
# RUN <<EOF
# mkdir -p build
# cd build
# cmake .. -DCMAKE_BUILD_TYPE=Release
# make -j$(nproc)
# EOF

# # Create a directory for logs
# RUN mkdir -p /.timbre

# # Set the entrypoint to the timbre executable
# ENTRYPOINT ["/app/build/timbre"]

# # Default command line arguments (can be overridden)
# CMD [] 