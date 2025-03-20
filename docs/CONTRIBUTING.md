# Contributing to Timbre

## Development Environment

### Prerequisites

You'll need:
- [Zig](https://ziglang.org/) (0.14.0 or later)
- Git
- Node.js (for commitlint)

For Debian packaging:
- dpkg-deb
- fakeroot

For static analysis:
- clang-tidy
- cppcheck

### Using the Development Container

The easiest way to get started is using the provided development container:

```bash
docker pull ghcr.io/krakjn/timbre
docker run -it --rm -v $(pwd):/workspace ghcr.io/krakjn/timbre
```

The container includes all necessary development tools:
- Zig
- C++ compiler
- Build tools
- Testing framework
- Commitlint
- Auto-changelog
- Debian packaging tools
- Static analysis tools (clang-tidy, cppcheck)

### Local Development Setup

Install commitlint:
```bash
npm install -g @commitlint/cli @commitlint/config-conventional
```

## Development Workflow

1. Create a feature branch
1. Make your changes
1. Write tests
1. Build and test:
   ```bash
   # Build the project
   zig build
   
   # Run tests
   zig build test
   
   # Build packages
   zig build package
   ```
1. Run static analysis:
   ```bash
   # Run clang-tidy
   zig build -Dclang-tidy=true
   
   # Run cppcheck
   zig build -Dcppcheck=true
   
   # Run both
   zig build -Dclang-tidy=true -Dcppcheck=true
   ```
   
   The static analyzers will check:
   - clang-tidy: clang-analyzer-* and portability-* checks
   - cppcheck: All default checks, with suppressions for third-party code
1. Commit changes (following conventional commits)
1. Create a pull request

### Pull Request Template

When creating a pull request, you must select one of the following version bump options:
- [ ] MAJOR: Breaking changes
- [ ] MINOR: New features
- [ ] PATCH: Bug fixes
- [ ] NONE: No version change

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/). See [commit_convention.md](commit_convention.md) for details.

## Static Analysis

### Running the Analyzers

```bash
# Run clang-tidy
zig build -Dclang-tidy=true

# Run cppcheck
zig build -Dcppcheck=true

# Run both
zig build -Dclang-tidy=true -Dcppcheck=true
```

### Clang-Tidy Configuration

Clang-tidy is configured to run the following checks:
- `clang-analyzer-*`: All static analyzer checks
- `portability-*`: All portability-related checks

The analyzer runs on the core source files:
- src/main.cpp
- src/timbre.cpp
- src/config.cpp
- src/log.cpp

Common clang-tidy warnings and how to fix them:
- `portability-simd-intrinsics`: Use portable SIMD intrinsics
- `clang-analyzer-core.NullDereference`: Check for null pointer dereferences
- `clang-analyzer-cplusplus.NewDelete`: Check for memory leaks
- `clang-analyzer-security.*`: Various security checks

### Cppcheck Configuration

Cppcheck runs with the following settings:
- Suppressed: "toomanyconfigs" warning
- Excluded paths:
  - ./inc/toml/*
  - ./inc/CLI/*
  - ./tests/*
- Include path: ./inc/timbre

Common cppcheck warnings and how to fix them:
- `uninitvar`: Initialize variables before use
- `memleak`: Fix memory leaks
- `nullpointer`: Check for null pointer dereferences
- `unusedFunction`: Remove unused functions

### Interpreting Results

Both tools will output warnings in the following format:
```
filename:line:column: warning: description [check-name]
```

Example:
```
src/main.cpp:42:5: warning: Variable 'foo' is used uninitialized [uninitvar]
```

To fix a warning:
1. Locate the file and line number
2. Read the warning description
3. Apply the suggested fix
4. Re-run the analyzer to verify the fix

### Suppressing False Positives

For clang-tidy, add a comment before the line:
```cpp
// NOLINTNEXTLINE(check-name)
int x = potentially_warning_code();
```

For cppcheck, add a comment on the same line:
```cpp
int x = potentially_warning_code(); // cppcheck-suppress warningId
```