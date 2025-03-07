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

The development container also supports both architectures:
```bash
# It will automatically use the correct architecture for your system
docker run -it --rm -v $(pwd):/app ghcr.io/krakjn/timbre:latest
```

This setup will:
1. Build both AMD64 and ARM64 packages
2. Create multi-arch Docker images
3. Provide architecture-specific Debian packages
4. Support cross-compilation in the development container

Would you like me to:
1. Add more architectures?
2. Explain any part in more detail?
3. Add more build configurations?

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

- [Workflow](docs/WORKFLOW.md) - Detailed CI/CD and development workflow
- [Contributing](docs/CONTRIBUTING.md) - How to contribute to Timbre
- [Changelog](CHANGELOG.md) - Version history and changes

## Building from Source

```bash
# Clone repository
git clone https://github.com/krakjn/timbre.git
cd timbre

# Build
make BUILD_TYPE=Release

# Install
sudo make install
```

## LICENSE

This project is licensed under the MIT License - see the [license](LICENSE) file for details.