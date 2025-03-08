# Contributing to Timbre

## Development Environment

### Using the Development Container

The easiest way to get started is using the provided development container:

```bash
make enter
```

The container includes all necessary development tools:
- CMake
- C++ compiler
- Build tools
- Testing framework
- Commitlint
- Auto-changelog

### Local Development Setup

If you prefer local development, you'll need:
- CMake (3.10+)
- C++17 compiler
- Node.js (for commitlint)
- Git

Install commitlint:
```bash
npm install -g @commitlint/cli @commitlint/config-conventional
```

## Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write tests
5. Commit changes (following conventional commits)
6. Create a pull request

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/). The format is: 