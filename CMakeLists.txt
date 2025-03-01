cmake_minimum_required(VERSION 3.10)
project(timbre VERSION 1.0)

# Specify the C++ standard (C++17 for std::filesystem)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# include(FetchContent)
# FetchContent_Declare(
#   toml11
#   GIT_REPOSITORY https://github.com/ToruNiina/toml11.git
#   GIT_TAG        v4.4.0
# )
# FetchContent_MakeAvailable(toml11)

# Option to build tests
option(BUILD_TESTS "Build the test suite" ON)

# Add include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/inc)

# Create a library target for the core functionality
add_library(timbre_lib STATIC
    src/log.cpp
    src/timbre.cpp
    src/config.cpp
)

# Set the include directories for the library
target_include_directories(timbre_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/inc
)

# Add executable that uses the library
add_executable(timbre src/main.cpp)
target_link_libraries(timbre PRIVATE timbre_lib)

# Install target
install(TARGETS timbre DESTINATION bin)

# Create .timbre directory during build
add_custom_command(
    TARGET timbre POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/.timbre
    COMMENT "Creating .timbre directory"
)

# Testing with Catch2
if(BUILD_TESTS)
    # Enable testing
    enable_testing()
    
    # Try to find Catch2 package
    find_package(Catch2 QUIET)
    
    # If not found, use FetchContent to download it
    if(NOT Catch2_FOUND)
        include(FetchContent)
        FetchContent_Declare(
            Catch2
            GIT_REPOSITORY https://github.com/catchorg/Catch2.git
            GIT_TAG v3.4.0
        )
        FetchContent_MakeAvailable(Catch2)
    endif()
    
    # Add test executable
    add_executable(timbre_tests tests/test_timbre.cpp)
    
    # Link against our library and Catch2
    target_link_libraries(timbre_tests PRIVATE timbre_lib Catch2::Catch2WithMain)
    
    # Explicitly set include directories for tests
    target_include_directories(timbre_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/inc
    )
    
    # Register tests with CTest
    include(CTest)
    include(Catch)
    catch_discover_tests(timbre_tests)
endif()
