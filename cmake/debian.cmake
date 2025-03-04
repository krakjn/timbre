# Enable CPack
set(CPACK_GENERATOR "DEB")

# Package information
set(CPACK_PACKAGE_NAME "timbre")
set(CPACK_PACKAGE_VERSION "${TIMBRE_VERSION_STRING}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A modern C++ logging utility")
set(CPACK_PACKAGE_DESCRIPTION "Timbre is a modern, efficient, and flexible logging utility for C++ applications. It provides a clean command-line interface for structured logging with support for multiple output formats and destinations.")
set(CPACK_PACKAGE_MAINTAINER "Tony B <krakjn@gmail.com>")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/krakjn/timbre")
set(CPACK_PACKAGE_VENDOR "Tony B")
set(CPACK_PACKAGE_CONTACT "krakjn@gmail.com")

# Debian specific settings
set(CPACK_DEBIAN_PACKAGE_SECTION "utils")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libcurl4-openssl-dev")
set(CPACK_DEBIAN_PACKAGE_BUILD_DEPENDS "debhelper-compat (= 13), cmake, g++, git, libcurl4-openssl-dev")

include(CPack) 