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

- CMake 3.14 or higher
- Ninja build system
- C++17 compatible compiler
- Catch2 (for tests, optional)

### Build Options

```bash
# Clone repository
git clone https://github.com/krakjn/timbre.git
cd timbre

# Build Targets
make                        # Build x86_64 Debug build (default)
make BUILD_TYPE=Release     # Build x86_64 Release build
make arm64                  # Build ARM64 Debug build
make all                    # Build both x86_64 and ARM64

# Package Creation
make deb                    # Create Debian packages for both architectures
make deb-x86_64             # Create x86_64 Debian package only
make deb-arm64              # Create ARM64 Debian package only

# Testing
make test                   # Run all tests
make test-x86_64            # Run x86_64 tests only

# Installation
sudo make install-x86_64    # Install x86_64 build
sudo make install-arm64     # Install ARM64 build
sudo make uninstall         # Uninstall current build

# Development Container
make enter                  # Enter development container
make docker-build           # Build development container
```

### Build Types

- `Debug`: Default build with debug symbols and no optimizations
- `Release`: Optimized build with LTO and architecture-specific optimizations
- `RelWithDebInfo`: Release build with debug symbols


## LICENSE

This project is licensed under the MIT License - see the [license](LICENSE) file for details.