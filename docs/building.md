# Building

Timbre uses Zig’s build system (`build.zig`).

## Local build

```bash
# Debug build (default)
zig build

# Optimized binary
zig build --release=fast
```

## Tests

```bash
zig build test
```

## Cross-compilation

Build artifacts for multiple targets:

```bash
zig build all
```

Typical output layout:

```
zig-out/
├── aarch64-linux-musl
├── aarch64-macos
├── aarch64-windows
├── x86_64-linux-musl
├── x86_64-macos
└── x86_64-windows
```

## Release archives

Tagged releases on GitHub produce `.tar.xz` archives per platform via the CI workflow (see [Workflow](workflow.md)).

## Container image

CI uses `ghcr.io/ballast-dev/timbre`. You can build the same image locally:

```bash
docker build -t timbre:latest - < Dockerfile
```

Or with the project `justfile`:

```bash
just img
```
