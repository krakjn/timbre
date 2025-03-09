set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L/usr/aarch64-linux-gnu/lib")
set(ARCH_COMPILE_OPTIONS "-march=armv8-a")
set(CMAKE_INSTALL_PREFIX "/usr/aarch64-linux-gnu" CACHE PATH "Installation prefix" FORCE)

# Configure QEMU for test execution
set(CMAKE_CROSSCOMPILING_EMULATOR "/usr/bin/qemu-aarch64-static")
set(ENV{QEMU_LD_PREFIX} "/usr/aarch64-linux-gnu")

# Search for programs only in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Search for libraries and headers only in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
# Export the architecture-specific compile options
set(TIMBRE_ARCH_COMPILE_OPTIONS ${ARCH_COMPILE_OPTIONS} CACHE INTERNAL "Architecture-specific compile options") 