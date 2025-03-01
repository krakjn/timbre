# Timbre - Structured Logging Tool

Timbre is a simple structured logging tool that filters and categorizes log messages based on their content.

## Features

- Filters log messages containing "ERROR" and "WARNING" into separate files
- Option to suppress terminal output
- Option to append to existing log files instead of overwriting
- Configurable log directory
- Verbose logging for diagnostics
- TOML configuration file support with regex pattern matching
- Robust error handling

## Building

### Prerequisites

- CMake (version 3.10 or higher)
- C++ compiler with C++17 support

### Build Instructions

```bash
# Build the project (creates build directory automatically)
make

# Build with Release configuration
make BUILD_TYPE=Release

# Clean build artifacts
make clean

# Remove build directory completely
make distclean
```

## Installation

```bash
# Install to default location (/usr/local)
make install

# Install to custom location
make install PREFIX=~/bin

# Uninstall
make uninstall
```

## Usage

```bash
# Build and run
make run

# Or run directly after building
./build/timbre

# Suppress terminal output
./build/timbre --quiet

# Append to existing log files
./build/timbre --append

# Enable verbose logging
./build/timbre --verbose

# Specify custom log directory
./build/timbre --log-dir=/path/to/logs

# Use a TOML configuration file
./build/timbre --config=timbre.toml

# Combine options
./build/timbre --quiet --append --verbose
```

## TOML Configuration

Timbre supports configuration via TOML files. Here's an example:

```toml
[timbre]
log_dir = "/var/log/timbre" 

[log_level]
# Define regex patterns for different log levels
debug = "debug"
warn = "WARN"
optional = "Optional"
error = "error|exception|fail"  # Extended regex pattern example
```

The configuration file allows you to:
- Set the log directory
- Define regex patterns for different log levels

All regex patterns support:
- Case-insensitive matching (e.g., "error" matches "ERROR", "error", and "Error")
- Extended regex syntax (e.g., "error|exception" matches either "error" or "exception")

## Log Files

Log files are stored in the `.timbre` directory by default (or as specified in the config):
- `.timbre/warn` - Contains messages with "WARNING" or matching the "warn" regex
- `.timbre/error` - Contains messages with "ERROR" or matching the "error" regex

## Testing

The project includes unit tests using the Catch2 framework.

```bash
# Build and run tests
cd build
ctest

# Or run the test executable directly for more detailed output
./build/timbre_tests
```

The test suite includes:
- Pattern detection tests
- Line processing tests
- Configuration file handling tests:
  - Testing with non-existent configuration files
  - Testing with invalid TOML syntax
  - Testing with missing required sections
  - Testing with invalid regex patterns
  - Testing with valid configuration files
  - Testing case-insensitive regex matching

## Diagnostics

Timbre provides diagnostic logging to stderr with different verbosity levels:
- Normal mode: Shows INFO, WARNING, and ERROR messages
- Verbose mode: Also shows DEBUG messages

Example output:
```
[INFO] Timbre started. Processing input...
[ERROR] Failed to open warning log file
[INFO] Processing complete. Lines processed: 42
``` 