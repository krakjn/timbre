# Configuration

Optional TOML configuration controls where logs are written and how lines are categorized.

## File format

```toml
[timbre]
log_dir = "/var/log/timbre"

[log_level]
# filename = "regex" (matching is case-insensitive)
debug = "debug"
warn = "warn(ing)?"
error = "error|exception|fail"
```

### `[timbre]`

| Key | Description |
|-----|-------------|
| `log_dir` | Directory for category log files. Can be overridden with `--log-dir` on the CLI. |

### `[log_level]`

Each key is the **output filename** (without path). The value is a **regular expression** tested against each input line. When a line matches, it is written to that file.

Rules are evaluated in file order; see the implementation in `src/config.zig` for edge cases when multiple patterns match.

## Example in the repository

An sample config lives at [`cfg/timbre.toml`](https://github.com/krakjn/timbre/blob/main/cfg/timbre.toml).

## CLI vs file

- `--config` selects the TOML file.
- `--log-dir` takes precedence over `log_dir` in the file when both are set.
