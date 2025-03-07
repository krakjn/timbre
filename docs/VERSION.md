# Automated Versioning System

This project uses an automated versioning system based on CMake that follows the [Semantic Versioning](https://semver.org/) format with branch-specific formats:

- **Main branch**: `MAJOR.MINOR.PATCH` (point releases)
- **Other branches**: `MAJOR.MINOR.PATCH+BUILD` (beta releases)

## How It Works

1. The version is stored in the `pkg/version.txt` file in one of two formats:
   ```
   MAJOR.MINOR.PATCH       # On main branch (point releases)
   MAJOR.MINOR.PATCH+BUILD # On other branches (beta releases)
   ```

2. Version numbers are incremented based on the type of changes:
   - **MAJOR**: Incremented for incompatible API changes
   - **MINOR**: Incremented for backward-compatible new features
   - **PATCH**: Incremented for backward-compatible bug fixes
   - **BUILD**: Automatically incremented for each PR build (only visible in beta releases)

3. The version information is made available in the code through the `timbre/version.h` header.

4. The versioning system is implemented in `cmake/version.cmake` and provides a clean API for the main CMakeLists.txt file.

5. Branch detection is automatic using Git commands, so the system knows whether to use the point release format or the beta release format.

## Pull Request Workflow

When creating a pull request, you must specify the type of version bump required:

1. Fill out the PR template and check ONE of the version bump options:
   - [ ] MAJOR - for incompatible API changes
   - [ ] MINOR - for backward-compatible new features
   - [ ] PATCH - for backward-compatible bug fixes
   - [ ] NONE - for documentation, refactoring, or CI/CD changes

2. During PR builds, the build number is automatically incremented and included in the version (e.g., `1.0.0+42`).

3. When the PR is merged to main, the selected version component (major, minor, or patch) is incremented based on your selection, but the build number is dropped (e.g., `1.0.0`).

## Using Version Information in Code

Include the version header in your code:

```cpp
#include "timbre/version.h"
```

The following macros are available:

- `TIMBRE_VERSION_MAJOR`: Major version number
- `TIMBRE_VERSION_MINOR`: Minor version number
- `TIMBRE_VERSION_PATCH`: Patch version number
- `TIMBRE_VERSION_BUILD`: Build number (only used in beta releases)
- `TIMBRE_VERSION_STRING`: Standard version string without build number (e.g., "1.0.0")
- `TIMBRE_VERSION_FULL`: Full version with build number if not on main (e.g., "1.0.0+42" or "1.0.0")

Example:

```cpp
// For all branches
std::cout << "Timbre version " << TIMBRE_VERSION_STRING << std::endl;

// For feature branches (shows build number)
std::cout << "Full version: " << TIMBRE_VERSION_FULL << std::endl;
```

## CI/CD Integration

The versioning system is integrated with CI/CD pipelines:

1. **PR Builds**: The `.github/workflows/pr-build.yml` workflow automatically increments the build number for each PR build and includes it in the version (e.g., `1.0.0+42`).

2. **Version Bumping**: The `.github/workflows/ci-version-bump.yml` workflow increments the version component selected in the PR when merged to main, but drops the build number (e.g., `1.0.0`).

3. **Beta Releases**: The `.github/workflows/beta-release.yml` workflow can be manually triggered to create a beta release with the build number included in the version (e.g., `1.0.0+42`).

4. **Skip Version Bumping**: Add `[skip-version]` or `[skip ci]` to your commit message to skip automatic version bumping.

## Debian Packaging Integration

The version file is located in `pkg/version.txt` to make it accessible to the Debian packaging system. This allows the Debian packaging tools to extract the version information directly from the source tree. 