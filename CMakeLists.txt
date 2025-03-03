cmake_minimum_required(VERSION 3.10)

include(cmake/version.cmake)

# Automatically increment version number based on pipeline
set(VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/pkg/version.txt")
versioning(${VERSION_FILE})

project(timbre VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})

# Define version variables for configuration
set(TIMBRE_VERSION_MAJOR ${VERSION_MAJOR})
set(TIMBRE_VERSION_MINOR ${VERSION_MINOR})
set(TIMBRE_VERSION_PATCH ${VERSION_PATCH})
set(TIMBRE_VERSION_BUILD ${VERSION_BUILD})
set(TIMBRE_VERSION_STRING ${VERSION_STRING})
set(TIMBRE_VERSION_FULL ${VERSION_FULL})

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/inc/timbre/version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/inc/timbre/version.h
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

option(BUILD_TESTS "Build the test suite" ON)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/inc)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/inc)

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

install(TARGETS timbre DESTINATION bin)

add_custom_command(
    TARGET timbre POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/.timbre
    COMMENT "Creating .timbre directory"
)

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
