# Timbre - Turn those logs into quality lumber 🪵

Debugging a program with tons of output? Pass them to `timbre`

## Features

- 🔍 Smart log filtering with regex support
- 📁 Organized log categorization
- ⚙️ TOML configuration
- 🚀 High performance
- 📊 Detailed diagnostics

```sh
./app_with_tons_of_output | timbre
```
Structured logs add soundness to the noise of development. Add custom filters and categories to timbre with a configuration file to chop those logs in their respective files.
```
ls -l .timbre/
  error.log
  warn.log
  info.log
  debug.log
```

[![CI](https://github.com/krakjn/timbre/actions/workflows/ci.yml/badge.svg)](https://github.com/krakjn/timbre/actions/workflows/ci.yml)
[![Release](https://github.com/krakjn/timbre/actions/workflows/release.yml/badge.svg)](https://github.com/krakjn/timbre/actions/workflows/release.yml)

## Quick Start

### Installation

Timbre provides packages for multiple architectures:

```bash
# For AMD64 (x86_64)
curl -LO https://github.com/krakjn/timbre/releases/latest/download/timbre_*_amd64.deb
sudo dpkg -i timbre_*_amd64.deb

# For ARM64 (aarch64)
curl -LO https://github.com/krakjn/timbre/releases/latest/download/timbre_*_arm64.deb
sudo dpkg -i timbre_*_arm64.deb
```

### Basic Usage

```bash
# Process logs with default settings
./app | timbre

# Use custom configuration
./app | timbre --config=timbre.toml

# Enable verbose output
./app | timbre --verbose
```

### Configuration

```toml
[timbre]
log_dir = "/var/log/timbre"

[log_level]
debug = "debug"
warn = "warn(ing)?"
error = "error|exception|fail"
```

## Documentation

- [Workflow](docs/workflow.md) - Detailed CI/CD and development workflow
- [Contributing](docs/contributing.md) - How to contribute to Timbre
- [Changelog](CHANGELOG.md) - Version history and changes
- [Commit Convention](docs/commit_convention.md)

## Building from Source

### Prerequisites

- Zig 0.14.0 or later
- A C++17 compatible compiler

### Build Instructions

Timbre uses Zig's build system for cross-compilation to various platforms. The build system automatically detects your platform and builds the appropriate version by default.

```bash
# Build for your current platform (debug)
zig build

# Build with release optimizations
zig build -Doptimize=ReleaseFast

# Run the application
zig build run
```

### Cross-Compilation Targets

Timbre supports building for multiple platforms:

```bash
# Build for specific platforms
zig build macos-arm64    # macOS ARM64 (Apple Silicon)
zig build macos-x86_64   # macOS Intel
zig build linux-arm64    # Linux ARM64 (musl)
zig build linux-x86_64   # Linux x86_64 (musl)
zig build windows-arm64  # Windows ARM64 (GNU)
zig build windows-x86_64 # Windows x86_64 (GNU)

# Build for all targets of a platform
zig build macos    # All macOS targets
zig build linux    # All Linux targets
zig build windows  # All Windows targets

# Build for all platforms
zig build all
```

### Build Output

Built binaries are placed in the `out` directory, organized by target triple:

```
out/
  aarch64-macos/      # macOS ARM64
  x86_64-macos/       # macOS Intel
  aarch64-linux-musl/ # Linux ARM64
  x86_64-linux-musl/  # Linux x86_64
  aarch64-windows-gnu/ # Windows ARM64
  x86_64-windows-gnu/  # Windows x86_64
```

### Testing

Tests can be run for any target platform:

```bash
# Run tests for specific platform
zig build test-macos-arm64
zig build test-linux-x86_64
zig build test-windows-x86_64

# Run tests for all platforms
zig build test-macos
zig build test-linux
zig build test-windows
```

### Build Options

- `-Doptimize=[Debug|ReleaseSafe|ReleaseFast|ReleaseSmall]`: Set optimization level
- `-Dprefix=[path]`: Set custom output directory (default: "out")
- `-Dtarget=[triple]`: Override target platform

## Project Structure

```
.
├── src/           # Source files
│   ├── main.cpp   # Main entry point
│   ├── timbre.cpp # Core audio processing
│   ├── config.cpp # Configuration handling
│   └── log.cpp    # Logging utilities
├── inc/           # Header files
├── tests/         # Test files
├── zig/          # Zig build configuration
│   └── common.zig # Common build settings
└── build.zig     # Build system definition
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## LICENSE

This project is licensed under the MIT License - see the [license](LICENSE) file for details.