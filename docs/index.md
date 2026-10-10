# Timbre

**Turn those logs into quality lumber.**

Timbre reads a stream of log lines from stdin, matches each line against configurable regex rules, and writes matching lines into category files under a log directory (by default `.timbre/`).

```bash
./app_with_tons_of_output | timbre
```

## Why Timbre?

When debugging or running integration tests, programs often emit far more output than you can read in the terminal. Timbre keeps the full stream on disk, split into files such as `error.log`, `warn.log`, and `debug.log`, so you can inspect failures without re-running the job.

## Features

- Pure Zig, including the regex engine
- Regex-based filtering and categorization
- Optional TOML configuration for custom rules and paths
- Append or overwrite log files per run

## Quick example

```bash
# Default rules and `.timbre/` output directory
./my_app 2>&1 | timbre

# Custom config and log directory
./my_app 2>&1 | timbre --config=timbre.toml --log-dir=/var/log/myapp
```

See [Getting started](getting-started.md) for install options and [Configuration](configuration.md) for the TOML format.
