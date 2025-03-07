cmake_minimum_required(VERSION 3.10)

include(cmake/version.cmake)

# Option to control static analysis in CI
option(STATIC_ANALYSIS "Run static analysis checks, impacts build time" OFF)
if(STATIC_ANALYSIS)
    include(cmake/static_analysis.cmake)
endif()

# Automatically increment version number based on pipeline
set(VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/pkg/version.txt")
versioning(${VERSION_FILE})

project(timbre VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})

set(TIMBRE_VERSION_MAJOR ${VERSION_MAJOR})
set(TIMBRE_VERSION_MINOR ${VERSION_MINOR})
set(TIMBRE_VERSION_PATCH ${VERSION_PATCH})
set(TIMBRE_VERSION_BUILD ${VERSION_BUILD})
set(TIMBRE_VERSION_STRING ${VERSION_STRING})

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/inc/timbre/version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/inc/timbre/version.h
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

option(BUILD_TESTS "Build the test suite" ON)

# External includes are SYSTEM to suppress warnings
include_directories(SYSTEM
    ${CMAKE_CURRENT_SOURCE_DIR}/inc/toml
    ${CMAKE_CURRENT_SOURCE_DIR}/inc/CLI
)

# Our includes are normal to enable warnings
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/inc/timbre
    ${CMAKE_CURRENT_BINARY_DIR}/inc/timbre
)

# Build library (for testing only)
add_library(timbre_lib STATIC
    src/log.cpp
    src/timbre.cpp
    src/config.cpp
)

target_include_directories(timbre_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/inc
    ${CMAKE_CURRENT_BINARY_DIR}/inc
)

add_executable(timbre src/main.cpp)
target_link_libraries(timbre PRIVATE timbre_lib)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(timbre PRIVATE 
        -O3                 # Maximum optimization level
        -DNDEBUG            # Disable assertions
        -flto               # Link-time optimization
        -ffat-lto-objects   # Enable fat LTO objects
        -flto-partition=one # Partition LTO objects into one file
        -march=native       # Optimize for current CPU architecture
        -funroll-loops      # Unroll loops for better performance
    )
endif()
# Additive, so the options below will be added to the ones specified earlier
target_compile_options(timbre PRIVATE -Wall -Wextra -Werror -pedantic)

if(STATIC_ANALYSIS)
    apply_static_analysis(timbre)
endif()

# Installation rules
install(TARGETS timbre
    RUNTIME DESTINATION bin
)

include(cmake/debian.cmake)

if(BUILD_TESTS)
    enable_testing()
    find_package(Catch2 QUIET)
    if(NOT Catch2_FOUND)
        include(FetchContent)
        FetchContent_Declare(
            Catch2
            GIT_REPOSITORY https://github.com/catchorg/Catch2.git
            GIT_TAG v3.4.0
        )
        FetchContent_MakeAvailable(Catch2)
    endif()
    add_executable(timbre_tests tests/test_timbre.cpp)
    target_link_libraries(timbre_tests PRIVATE timbre_lib Catch2::Catch2WithMain)
    target_include_directories(timbre_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/inc
        ${CMAKE_CURRENT_BINARY_DIR}/inc
    )
    
    include(CTest)
    include(Catch)
    catch_discover_tests(timbre_tests)
endif()

# Add architecture-specific settings
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
    set(ARCH "arm64")
else()
    set(ARCH "amd64")
endif()

# Update package name to include architecture
set(CPACK_PACKAGE_FILE_NAME "timbre_${PROJECT_VERSION}_${ARCH}")
