find_program(CLANG_TIDY_EXE NAMES clang-tidy)
if(CLANG_TIDY_EXE)
    message(STATUS "Found clang-tidy: ${CLANG_TIDY_EXE}")
    
    # Configure clang-tidy checks:
    # Only enable:
    # clang-analyzer-* : Static analyzer checks
    # portability-*    : Portability-related issues
    set(CLANG_TIDY_CHECKS "-*,clang-analyzer-*,portability-*")
    
    set(CMAKE_CXX_CLANG_TIDY 
        ${CLANG_TIDY_EXE}
        -checks=${CLANG_TIDY_CHECKS}
    )
else()
    message(WARNING "clang-tidy not found!")
endif()

# Find cppcheck
find_program(CPPCHECK_EXE NAMES cppcheck)
if(CPPCHECK_EXE)
    message(STATUS "Found cppcheck: ${CPPCHECK_EXE}")
    set(CMAKE_CXX_CPPCHECK 
        ${CPPCHECK_EXE}
        -I ${CMAKE_SOURCE_DIR}/inc/timbre
        # Ignore external libraries
        --suppress=*:${CMAKE_SOURCE_DIR}/inc/toml/*
        --suppress=*:${CMAKE_SOURCE_DIR}/inc/CLI/*
        --suppress=*:${CMAKE_SOURCE_DIR}/tests/*
        --suppress=*:*/catch2/*
        --suppress=*:*/Catch2/*
    )
else()
    message(WARNING "cppcheck not found!")
endif()

# Function to apply static analysis to a target
function(apply_static_analysis TARGET_NAME)
    # Don't apply static analysis to test targets
    if(${TARGET_NAME} MATCHES ".*test.*")
        return()
    endif()

    if(CLANG_TIDY_EXE)
        set_target_properties(${TARGET_NAME} PROPERTIES
            CXX_CLANG_TIDY "${CMAKE_CXX_CLANG_TIDY}"
        )
    endif()
    
    if(CPPCHECK_EXE)
        set_target_properties(${TARGET_NAME} PROPERTIES
            CXX_CPPCHECK "${CMAKE_CXX_CPPCHECK}"
        )
    endif()
endfunction() 