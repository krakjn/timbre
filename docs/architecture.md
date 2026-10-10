# Timbre Architecture

## Overview

Timbre is a Zig application that filters stdin through regex rules and writes categorized log files. The codebase is small and modular: CLI parsing, configuration, logging, and the core line-matching loop are separate compilation units, built with Zig’s native build system.

## Component Architecture

```mermaid
graph TB
    CLI[CLI Interface] --> Config[Config Manager]
    CLI --> Core[Core Engine]
    
    Config --> FileSystem[File System]
    Config --> Version[Version Info]
    
    Core --> Log[Logger]
    Core --> Worker[Worker Threads]
    
    Worker --> FileSystem
    Worker --> Log
    
    subgraph Build System
        Zig --> Version
        Zig --> Static[Static Analysis]
        Zig --> Tests[Test Suite]
    end
```

## Key Components

### Build System
- Zig-based build system
- Multi-architecture support (x86_64, arm64)
- Integrated static analysis (clang-tidy, cppcheck)
- Automated testing with Zig test runner
- Version management system

### Core Components

- **CLI** (`src/cli.zig`): Argument parsing and help text
- **Config** (`src/config.zig`): TOML configuration and log-level rules
- **Log** (`src/log.zig`): File output and terminal behavior
- **Timbre** (`src/timbre.zig`): Core filtering pipeline
- **Main** (`src/main.zig`): Entry point and wiring

## Build Configurations

```mermaid
graph LR
    Source[Source Code] --> Debug[Debug Build]
    Source --> Release[Release Build]
    
    Debug --> Tests[Run Tests]
    Release --> Package[Create Package]
    
    Package --> DEB[Debian Package]
    
    subgraph Optimizations
        Release --> O3[O3 Optimization]
        Release --> LTO[Link Time Opt]
        Release --> Unroll[Loop Unroll]
    end
```

## Development Workflow

```mermaid
graph LR
    Dev[Development] --> Branch[Feature Branch]
    Branch --> PR[Pull Request]
    PR --> CI[CI Pipeline]
    
    CI --> Lint[Commit Lint]
    CI --> Build[Build & Test]
    CI --> Analysis[Static Analysis]
    
    Analysis --> Merge[Merge to Main]
    Build --> Merge
    Lint --> Merge
    
    Merge --> Release[Create Release]
```

## File organization

```
timbre/
├── src/
│   ├── main.zig              # Entry point
│   ├── timbre.zig            # Core filtering
│   ├── config.zig            # TOML configuration
│   ├── log.zig               # Log file I/O
│   ├── cli.zig               # CLI parsing
│   └── integration_test.zig  # Integration tests
├── regex/                    # Bundled regex library (Zig)
├── cfg/                      # Example timbre.toml
├── docs/                     # Documentation (MkDocs source)
├── build.zig                 # Build definition
└── Dockerfile                # CI / dev container image
``` 