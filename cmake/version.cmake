# CMake module for automated versioning

# Version bumping is controlled by the VERSION_BUMP option
# Set -DVERSION_BUMP=ON to enable automatic build number incrementation
# This is typically enabled in CI environments but disabled for normal development builds

# Options to control version bumping
option(VERSION_BUMP "To bump or not to bump, that is the question; answered by CI" OFF)
option(BUMP_MAJOR "Flag to bump major version" OFF)
option(BUMP_MINOR "Flag to bump minor version" OFF)
option(BUMP_PATCH "Flag to bump patch version" OFF)


function(is_on_main_branch RESULT_VAR)
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        OUTPUT_VARIABLE CURRENT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE GIT_RESULT
    )
    
    if(GIT_RESULT EQUAL 0 AND CURRENT_BRANCH STREQUAL "main")
        set(${RESULT_VAR} TRUE PARENT_SCOPE)
    else()
        set(${RESULT_VAR} FALSE PARENT_SCOPE)
    endif()
endfunction()


function(load_semver_vars_from_file VERSION_FILE)
    file(READ ${VERSION_FILE} VERSION_CONTENT)
    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)(\\+([0-9]+))?$" VERSION_MATCH "${VERSION_CONTENT}")
    if(NOT VERSION_MATCH)
        message(FATAL_ERROR "Invalid version format in ${VERSION_FILE}")
    endif()
    set(VERSION_MAJOR ${CMAKE_MATCH_1} PARENT_SCOPE)
    set(VERSION_MINOR ${CMAKE_MATCH_2} PARENT_SCOPE)
    set(VERSION_PATCH ${CMAKE_MATCH_3} PARENT_SCOPE)
    
    # Build number might not be present
    if(CMAKE_MATCH_5)
        set(VERSION_BUILD ${CMAKE_MATCH_5} PARENT_SCOPE)
    else()
        set(VERSION_BUILD "0" PARENT_SCOPE)
    endif()
    
    # Set the full version string (without build number)
    set(VERSION_STRING "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}" PARENT_SCOPE)
    
    # Set the full version string (with build number)
    if(CMAKE_MATCH_5)
        set(VERSION_FULL "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}+${CMAKE_MATCH_5}" PARENT_SCOPE)
    else()
        set(VERSION_FULL "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}" PARENT_SCOPE)
    endif()
endfunction()


# Function to increment version based on type (major, minor, patch)
function(increment VERSION_FILE TYPE ON_MAIN)
    # Read the current version
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
    elseif(TYPE STREQUAL "build")
        set(NEW_MAJOR "${VERSION_MAJOR}")
        set(NEW_MINOR "${VERSION_MINOR}")
        set(NEW_PATCH "${VERSION_PATCH}")
        math(EXPR NEW_BUILD "${VERSION_BUILD} + 1")
    else()
        message(FATAL_ERROR "Invalid version increment type: ${TYPE}")
    endif()
    
    # Write the updated version back to the file
    # Format depends on whether we're on main branch
    if(ON_MAIN)
        # On main, don't include build number
        file(WRITE ${VERSION_FILE} "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}")
        set(VERSION_FULL "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}" PARENT_SCOPE)
        message(STATUS "Incremented ${TYPE} to ${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH} (point release)")
    else()
        # Not on main, include build number
        file(WRITE ${VERSION_FILE} "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}+${NEW_BUILD}")
        set(VERSION_FULL "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}+${NEW_BUILD}" PARENT_SCOPE)
        message(STATUS "Incremented to ${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}+${NEW_BUILD} (beta release)")
    endif()
    
    # Update parent scope variables
    set(VERSION_MAJOR ${NEW_MAJOR} PARENT_SCOPE)
    set(VERSION_MINOR ${NEW_MINOR} PARENT_SCOPE)
    set(VERSION_PATCH ${NEW_PATCH} PARENT_SCOPE)
    set(VERSION_BUILD ${NEW_BUILD} PARENT_SCOPE)
    set(VERSION_STRING "${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}" PARENT_SCOPE)
endfunction()

    
function(bump_semver VERSION_FILE ON_MAIN BUMP_MAJOR BUMP_MINOR BUMP_PATCH)
    if(BUMP_MAJOR)
        increment(${VERSION_FILE} "major" ${ON_MAIN})
    elseif(BUMP_MINOR)
        increment(${VERSION_FILE} "minor" ${ON_MAIN})
    elseif(BUMP_PATCH)
        increment(${VERSION_FILE} "patch" ${ON_MAIN})
    else()
        increment(${VERSION_FILE} "build" ${ON_MAIN})
    endif()
    # Reload the version file to ensure we have the latest values
    load_semver_vars_from_file(${VERSION_FILE})
endfunction()


function(versioning VERSION_FILE)
    is_on_main_branch(ON_MAIN)
    load_semver_vars_from_file(${VERSION_FILE})
    
    if(VERSION_BUMP)
        bump_semver(
            ${VERSION_FILE}
            ${ON_MAIN}
            ${BUMP_MAJOR} 
            ${BUMP_MINOR} 
            ${BUMP_PATCH} 
        )
    endif()
    
    # Export all version variables to parent scope
    set(ON_MAIN ${ON_MAIN} PARENT_SCOPE)
    set(VERSION_MAJOR ${VERSION_MAJOR} PARENT_SCOPE)
    set(VERSION_MINOR ${VERSION_MINOR} PARENT_SCOPE)
    set(VERSION_PATCH ${VERSION_PATCH} PARENT_SCOPE)
    set(VERSION_BUILD ${VERSION_BUILD} PARENT_SCOPE)
    set(VERSION_STRING ${VERSION_STRING} PARENT_SCOPE)
    set(VERSION_FULL ${VERSION_FULL} PARENT_SCOPE)
endfunction()