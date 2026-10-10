# Timbre - Turn those logs into quality lumber 🪵

Debugging a program with tons of output? Pass them to `timbre`

[![CI](https://github.com/krakjn/timbre/actions/workflows/ci.yml/badge.svg)](https://github.com/krakjn/timbre/actions/workflows/ci.yml)
[![Docs](https://github.com/krakjn/timbre/actions/workflows/docs.yml/badge.svg)](https://github.com/krakjn/timbre/actions/workflows/docs.yml)

**Documentation:** [https://krakjn.github.io/timbre/](https://krakjn.github.io/timbre/) (built and published by the [docs workflow](.github/workflows/docs.yml) on each push to `main`). Local preview: `pip install -r requirements-docs.txt && mkdocs serve`

## Features

- Pure zig, even the regex lib 
- Log filter with regex!
- Categorize your logs to each filter
- \[Optional\] toml configuration

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

## Basic Usage

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


## Building from Source

### Prerequisites

- Zig 0.15.0 or later

### Build Instructions

#### Container building is encouraged!
1. First **get Docker**
    - [Download Docker Desktop](https://www.docker.com) (for Windows and Mac)
    - Use your package manager in Linux, i.e. `apt`, `pacman`, etc...
    - Or just run: `curl -fsSL https://get.docker.com | sh -`
1. Get code, `git clone https://github.com/krakjn/timbre.git && cd timbre` 
1. Build image, `docker build -t timbre:latest - < Dockerfile`
1. Jump into image, 

       docker run -it --rm -v $(pwd):/app -w /app timbre:latest 

#### Zig Build System!
Timbre uses Zig's build system for cross-compilation to various platforms. The build system automatically detects your platform and builds the appropriate version by default.

```bash
# Build for your current platform (debug)
zig build

# Build with release optimizations
zig build --release=fast
```

### Cross-Compilation Targets

Timbre supports building for multiple platforms:

```bash
zig build all
```

### Build Output
```
zig-out/
|-- aarch64-linux-musl
|-- aarch64-macos
|-- aarch64-windows
|-- x86_64-linux-musl
|-- x86_64-macos
`-- x86_64-windows
```

### Testing

Tests can be run for any target platform:

```bash
zig build test
```

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
└── build.zig      # Build system definition
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## LICENSE

This project is licensed under the MIT License - see the [license](LICENSE) file for details.