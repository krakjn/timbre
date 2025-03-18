#  ______   __     __    __     ______     ______     ______    
# /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\   
# \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\   
#    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\ 
#     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/ 

# Default build type is Debug
BUILD_TYPE ?= Debug
PREFIX ?= /usr/local/bin
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# Build directories with precise architecture names
BUILD_MACOS_ARM64 = out/aarch64-macos
BUILD_MACOS_X86_64 = out/x86_64-macos
BUILD_LINUX_ARM64 = out/aarch64-linux-musl
BUILD_LINUX_X86_64 = out/x86_64-linux-musl
BUILD_WINDOWS_ARM64 = out/aarch64-windows-gnu
BUILD_WINDOWS_X86_64 = out/x86_64-windows-msvc

# Map build types to Zig optimization levels
ifeq ($(BUILD_TYPE),Debug)
    ZIG_OPT := Debug
else ifeq ($(BUILD_TYPE),Release)
    ZIG_OPT := ReleaseFast
else ifeq ($(BUILD_TYPE),RelWithDebInfo)
    ZIG_OPT := ReleaseSafe
endif

# Default target is native build
.PHONY: default
default: native

# Create build directories
$(BUILD_MACOS_ARM64):
	@mkdir -p $(BUILD_MACOS_ARM64)

$(BUILD_MACOS_X86_64):
	@mkdir -p $(BUILD_MACOS_X86_64)

$(BUILD_LINUX_ARM64):
	@mkdir -p $(BUILD_LINUX_ARM64)

$(BUILD_LINUX_X86_64):
	@mkdir -p $(BUILD_LINUX_X86_64)

$(BUILD_WINDOWS_ARM64):
	@mkdir -p $(BUILD_WINDOWS_ARM64)

$(BUILD_WINDOWS_X86_64):
	@mkdir -p $(BUILD_WINDOWS_X86_64)

# Native build based on host system
.PHONY: native
native:
	@case "$$(uname -s)-$$(uname -m)" in \
		"Darwin-arm64") make macos-arm64 ;; \
		"Darwin-x86_64") make macos-x86_64 ;; \
		"Linux-aarch64") make linux-arm64 ;; \
		"Linux-x86_64") make linux-x86_64 ;; \
		"Windows"*"ARM64") make windows-arm64 ;; \
		"Windows"*"x86_64") make windows-x86_64 ;; \
		*) echo "Unsupported platform" && exit 1 ;; \
	esac

# macOS targets
.PHONY: macos-arm64
macos-arm64: $(BUILD_MACOS_ARM64)
	@zig build \
		-Dtarget=aarch64-macos \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_MACOS_ARM64) \
		-j$(NPROC)

.PHONY: macos-x86_64
macos-x86_64: $(BUILD_MACOS_X86_64)
	@zig build \
		-Dtarget=x86_64-macos \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_MACOS_X86_64) \
		-j$(NPROC)

.PHONY: macos
macos: macos-arm64 macos-x86_64

# Linux targets
.PHONY: linux-arm64
linux-arm64: $(BUILD_LINUX_ARM64)
	@zig build \
		-Dtarget=aarch64-linux-musl \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_LINUX_ARM64) \
		-j$(NPROC)

.PHONY: linux-x86_64
linux-x86_64: $(BUILD_LINUX_X86_64)
	@zig build \
		-Dtarget=x86_64-linux-musl \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_LINUX_X86_64) \
		-j$(NPROC)

.PHONY: linux
linux: linux-arm64 linux-x86_64

# Windows targets (MSVC for x86_64, GNU for ARM64)
.PHONY: windows-arm64
windows-arm64: $(BUILD_WINDOWS_ARM64)
	@zig build \
		-Dtarget=aarch64-windows-gnu \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_WINDOWS_ARM64) \
		-j$(NPROC)

.PHONY: windows-x86_64
windows-x86_64: $(BUILD_WINDOWS_X86_64)
	@zig build \
		-Dtarget=x86_64-windows-msvc \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_WINDOWS_X86_64) \
		-j$(NPROC)

.PHONY: windows
windows: windows-arm64 windows-x86_64

# Build all targets
.PHONY: all
all: macos linux windows

# Clean build artifacts
.PHONY: clean
clean:
	@rm -rf zig-out zig-cache out

# Test targets
.PHONY: test-macos
test-macos: macos
	@zig build test \
		-Dtarget=aarch64-macos \
		-Doptimize=$(ZIG_OPT)
	@zig build test \
		-Dtarget=x86_64-macos \
		-Doptimize=$(ZIG_OPT)

.PHONY: test-linux
test-linux: linux
	@zig build test \
		-Dtarget=aarch64-linux-musl \
		-Doptimize=$(ZIG_OPT)
	@zig build test \
		-Dtarget=x86_64-linux-musl \
		-Doptimize=$(ZIG_OPT)

.PHONY: test-windows
test-windows: windows
	@zig build test \
		-Dtarget=aarch64-windows-gnu \
		-Doptimize=$(ZIG_OPT)
	@zig build test \
		-Dtarget=x86_64-windows-gnu \
		-Doptimize=$(ZIG_OPT)

.PHONY: test
test: test-macos test-linux test-windows

# Help target
.PHONY: help
help:
	@echo "Makefile for timbre project (Zig Build System)"
	@echo ""
	@echo "Targets:"
	@echo "  native           - Build for current platform"
	@echo "  macos           - Build for macOS (arm64 and x86_64)"
	@echo "  linux           - Build for Linux (arm64 and x86_64)"
	@echo "  windows         - Build for Windows (x86_64 MSVC)"
	@echo "  all             - Build for all platforms"
	@echo "  clean           - Clean build artifacts"
	@echo "  test            - Run tests for all platforms"
	@echo ""
	@echo "Platform-specific targets:"
	@echo "  macos-arm64     - Build for macOS ARM64 (Apple Silicon)"
	@echo "  macos-x86_64    - Build for macOS x86_64"
	@echo "  linux-arm64     - Build for Linux ARM64 (musl)"
	@echo "  linux-x86_64    - Build for Linux x86_64 (musl)"
	@echo "  windows-arm64   - Build for Windows ARM64 (GNU)"
	@echo "  windows-x86_64  - Build for Windows x86_64 (MSVC)"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_TYPE      - Build type: Debug, Release, or RelWithDebInfo (default: Debug)"
	@echo "  PREFIX          - Installation prefix (default: /usr/local/bin)"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build for current platform"
	@echo "  make all               # Build for all platforms"
	@echo "  make macos            # Build for all macOS targets"
	@echo "  make BUILD_TYPE=Release linux-x86_64  # Build Linux x86_64 release"
