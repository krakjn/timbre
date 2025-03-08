# CMake module for automated versioning

# Version bumping is controlled by the VERSION_BUMP option
# Set -DVERSION_BUMP=ON to enable automatic build number incrementation
# This is typically enabled in CI environments but disabled for normal development builds

# Options to control version bumping
option(VERSION_BUMP "To bump or not to bump, that is the question; answered by CI" OFF)
option(BUMP_MAJOR "Flag to bump major version" OFF)
option(BUMP_MINOR "Flag to bump minor version" OFF)
option(BUMP_PATCH "Flag to bump patch version" OFF)


function(is_dev_branch RESULT_VAR)
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        OUTPUT_VARIABLE CURRENT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE GIT_RESULT
    )
    
    if(GIT_RESULT EQUAL 0 AND NOT CURRENT_BRANCH STREQUAL "main")
        set(${RESULT_VAR} 1 PARENT_SCOPE)
    else()
        set(${RESULT_VAR} 0 PARENT_SCOPE)
    endif()
endfunction()


function(get_git_sha RESULT_VAR)
    execute_process(
        COMMAND git rev-parse --short=8 HEAD
        OUTPUT_VARIABLE GIT_SHA
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE GIT_RESULT
    )
    
    if(GIT_RESULT EQUAL 0)
        set(${RESULT_VAR} "${GIT_SHA}" PARENT_SCOPE)
    else()
        set(${RESULT_VAR} "" PARENT_SCOPE)
    endif()
endfunction()


function(load_semver_vars_from_file VERSION_FILE)
    file(READ ${VERSION_FILE} VERSION_CONTENT)
    string(STRIP "${VERSION_CONTENT}" VERSION_CONTENT) # Strip any whitespace or newlines
    
    # Match clean version only
    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)$" VERSION_MATCH "${VERSION_CONTENT}")
    if(NOT VERSION_MATCH)
        message(FATAL_ERROR "Invalid version format ${VERSION_CONTENT} in ${VERSION_FILE}")
    endif()
    
    set(VERSION_MAJOR ${CMAKE_MATCH_1} PARENT_SCOPE)
    set(VERSION_MINOR ${CMAKE_MATCH_2} PARENT_SCOPE)
    set(VERSION_PATCH ${CMAKE_MATCH_3} PARENT_SCOPE)
endfunction()


# Function to increment version based on type (major, minor, patch)
function(increment VERSION_FILE TYPE)
    load_semver_vars_from_file(${VERSION_FILE})
    
    # Honors semver increment rules
    if(TYPE STREQUAL "major")
        math(EXPR NEW_MAJOR "${VERSION_MAJOR} + 1")
        set(NEW_MINOR "0")
        set(NEW_PATCH "0")
    elseif(TYPE STREQUAL "minor")
        set(NEW_MAJOR "${VERSION_MAJOR}")
        math(EXPR NEW_MINOR "${VERSION_MINOR} + 1")
        set(NEW_PATCH "0")
    elseif(TYPE STREQUAL "patch")
        set(NEW_MAJOR "${VERSION_MAJOR}")
        set(NEW_MINOR "${VERSION_MINOR}")
        math(EXPR NEW_PATCH "${VERSION_PATCH} + 1")
    else()
        set(NEW_MAJOR "${VERSION_MAJOR}")
        set(NEW_MINOR "${VERSION_MINOR}")
        set(NEW_PATCH "${VERSION_PATCH}")
    endif()
    
    # Always write clean version to file
    set(NEW_VERSION_STRING "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}")
    file(WRITE ${VERSION_FILE} "${NEW_VERSION_STRING}")
    
    # Update parent scope variables
    set(VERSION_MAJOR ${NEW_MAJOR} PARENT_SCOPE)
    set(VERSION_MINOR ${NEW_MINOR} PARENT_SCOPE)
    set(VERSION_PATCH ${NEW_PATCH} PARENT_SCOPE)
endfunction()

    
function(bump_semver VERSION_FILE BUMP_MAJOR BUMP_MINOR BUMP_PATCH)
    if(BUMP_MAJOR)
        increment(${VERSION_FILE} "major")
    elseif(BUMP_MINOR)
        increment(${VERSION_FILE} "minor")
    elseif(BUMP_PATCH)
        increment(${VERSION_FILE} "patch")
    else()
        load_semver_vars_from_file(${VERSION_FILE})
    endif()
endfunction()


function(versioning VERSION_FILE)
    is_dev_branch(IS_DEV)
    get_git_sha(GIT_SHA)
    load_semver_vars_from_file(${VERSION_FILE})
    
    if(VERSION_BUMP)
        bump_semver(
            ${VERSION_FILE}
            ${BUMP_MAJOR} 
            ${BUMP_MINOR} 
            ${BUMP_PATCH} 
        )
        # Reload after potential bump
        load_semver_vars_from_file(${VERSION_FILE})
    endif()
    
    # Export all version variables to parent scope
    set(IS_DEV ${IS_DEV} PARENT_SCOPE)
    set(VERSION_MAJOR ${VERSION_MAJOR} PARENT_SCOPE)
    set(VERSION_MINOR ${VERSION_MINOR} PARENT_SCOPE)
    set(VERSION_PATCH ${VERSION_PATCH} PARENT_SCOPE)
    set(VERSION_SHA ${GIT_SHA} PARENT_SCOPE)
endfunction()