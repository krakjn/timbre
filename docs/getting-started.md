# Getting started

## Prerequisites

- A Unix-like environment (Linux, macOS, or WSL), or Windows builds via cross-compilation
- [Zig](https://ziglang.org/) 0.15.0 or later to build from source

## Install from source

```bash
git clone https://github.com/krakjn/timbre.git
cd timbre
zig build --release=fast
```

The binary is written under `zig-out/bin/` (exact path depends on your target triple).

## Run

Pipe any line-oriented output into `timbre`:

```bash
./zig-out/bin/timbre --help
./my_program 2>&1 | ./zig-out/bin/timbre
```

After a run with default settings, inspect categorized logs:

```bash
ls -l .timbre/
# error.log  warn.log  info.log  debug.log  ...
```

## Docker (recommended for builds)

The repository includes a `Dockerfile` used in CI. To build inside a container:

```bash
docker build -t timbre:latest - < Dockerfile
docker run -it --rm -v "$(pwd):/app" -w /app timbre:latest zig build --release=fast
```

## Next steps

- [Usage](usage.md) — CLI flags and behavior
- [Configuration](configuration.md) — TOML rules and log directories
- [Building](building.md) — cross-compilation and release builds
