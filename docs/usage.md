# Usage

Timbre is designed as a **stdin filter**: it reads lines from standard input and routes them to log files based on regex rules.

## Basic invocation

```bash
command | timbre
command 2>&1 | timbre
```

If you do not pass `--config`, Timbre uses built-in default categories. With `--config`, rules come from your TOML file (see [Configuration](configuration.md)).

## Command-line options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Print help |
| `-V`, `--version` | Print version |
| `-q`, `--quiet` | Suppress terminal output |
| `-a`, `--append` | Append to log files instead of overwriting |
| `-v`, `--verbose` | Increase verbosity (repeat `-vv`, `-vvv`, …) |
| `-d`, `--log-dir <DIR>` | Directory for categorized log files |
| `-c`, `--config <FILE>` | Path to TOML configuration |
| `--log-dir=<DIR>` | Same as `-d` |
| `--config=<FILE>` | Same as `-c` |

Short flags `-q`, `-a`, `-v`, and `-V` can be combined when they do not take arguments (for example `timbre -qa`).

## Examples

```bash
# Quiet run: only write files, minimal terminal noise
./server 2>&1 | timbre -q

# Keep history across runs
./server 2>&1 | timbre -a

# Custom config and output location
./server 2>&1 | timbre --config=./cfg/timbre.toml --log-dir=/tmp/myapp-logs
```

## Output layout

Each configured category becomes a file in the log directory. The default directory is `.timbre/` in the current working directory unless overridden in the config or with `--log-dir`.
