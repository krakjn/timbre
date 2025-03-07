# Unified toolchain file for multi-architecture builds
# Usage: Set TIMBRE_TARGET_ARCH to "amd64" or "arm64" before including this file

if(NOT DEFINED TIMBRE_TARGET_ARCH)
    message(FATAL_ERROR "TIMBRE_TARGET_ARCH must be defined to either 'amd64' or 'arm64'")
endif()

# Common settings
set(CMAKE_SYSTEM_NAME Linux)

if(TIMBRE_TARGET_ARCH STREQUAL "arm64")
    # ARM64 specific settings
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
    
    # Specify the cross-compiler
    set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
    set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)
    
    # Where to look for the target environment
    set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
    
    # Architecture-specific optimization flags
    set(ARCH_COMPILE_OPTIONS "-march=armv8-a")
    
    # Set the install prefix for this architecture
    set(CMAKE_INSTALL_PREFIX "/usr/aarch64-linux-gnu" CACHE PATH "Installation prefix" FORCE)
    
    # Search for programs only in the build host directories
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    
    # Search for libraries and headers only in the target directories
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
else()
    # AMD64 (x86_64) specific settings
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
    
    # Use native compiler
    set(CMAKE_C_COMPILER /usr/bin/gcc)
    set(CMAKE_CXX_COMPILER /usr/bin/g++)
    
    # Architecture-specific optimization flags
    set(ARCH_COMPILE_OPTIONS "-march=x86-64-v3")
    
    # Set the install prefix for this architecture
    set(CMAKE_INSTALL_PREFIX "/usr/local" CACHE PATH "Installation prefix" FORCE)
endif()

# Export the architecture-specific compile options as a variable
set(TIMBRE_ARCH_COMPILE_OPTIONS ${ARCH_COMPILE_OPTIONS} CACHE INTERNAL "Architecture-specific compile options") 