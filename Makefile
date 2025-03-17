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
BUILD_X86_64 = zig-out/x86_64
BUILD_ARM64 = zig-out/arm64

# Map build types to Zig optimization levels
ifeq ($(BUILD_TYPE),Debug)
    ZIG_OPT := Debug
else ifeq ($(BUILD_TYPE),Release)
    ZIG_OPT := ReleaseFast
else ifeq ($(BUILD_TYPE),RelWithDebInfo)
    ZIG_OPT := ReleaseSafe
endif

# Default target is x86_64, as most users will be on Intel/AMD
.PHONY: default
default: x86_64 

$(BUILD_X86_64):
	@mkdir -p $(BUILD_X86_64)

$(BUILD_ARM64):
	@mkdir -p $(BUILD_ARM64)

.PHONY: x86_64
x86_64: $(BUILD_X86_64)
	@zig build \
		-Dtarget=x86_64-linux-gnu \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_X86_64) \
		-j$(NPROC)

.PHONY: arm64
arm64: $(BUILD_ARM64)
	@zig build \
		-Dtarget=aarch64-linux-gnu \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(BUILD_ARM64) \
		-j$(NPROC)

.PHONY: all
all: x86_64 arm64

.PHONY: clean
clean:
	@rm -rf zig-out zig-cache

.PHONY: deb-x86_64
deb-x86_64: x86_64
	@scripts/package.sh x86_64 $(BUILD_X86_64) $(BUILD_TYPE)

.PHONY: deb-arm64
deb-arm64: arm64
	@scripts/package.sh arm64 $(BUILD_ARM64) $(BUILD_TYPE)

.PHONY: deb
deb: deb-x86_64 deb-arm64

.PHONY: enter
enter:
	@docker run -it --rm \
		-v $(PWD):/app \
		-w /app \
		--hostname timbre \
		ghcr.io/krakjn/timbre:latest

.PHONY: install-x86_64
install-x86_64: x86_64
	@echo "Installing $(BUILD_TYPE) configuration to $(PREFIX)..."
	@zig build install \
		-Dtarget=x86_64-linux-gnu \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(PREFIX)

.PHONY: install-arm64
install-arm64: arm64
	@echo "Installing $(BUILD_TYPE) configuration for arm64..."
	@zig build install \
		-Dtarget=aarch64-linux-gnu \
		-Doptimize=$(ZIG_OPT) \
		--prefix $(PREFIX)

.PHONY: uninstall
uninstall:
	@if [ -f "$(PREFIX)/bin/timbre" ]; then \
		rm -f "$(PREFIX)/bin/timbre"; \
		echo "Uninstalled timbre from $(PREFIX)/bin"; \
	else \
		echo "timbre not found in $(PREFIX)/bin"; \
		exit 1; \
	fi

.PHONY: test-x86_64
test-x86_64: x86_64
	@zig build test \
		-Dtarget=x86_64-linux-gnu \
		-Doptimize=$(ZIG_OPT)

.PHONY: test-arm64
test-arm64: arm64
	@echo "Note: Running ARM64 tests on non-ARM platform may require emulation"
	@zig build test \
		-Dtarget=aarch64-linux-gnu \
		-Doptimize=$(ZIG_OPT)

.PHONY: test
test: test-x86_64 test-arm64

# Build the Docker image without context
.PHONY: docker-build
docker-build:
	@docker build --platform linux/amd64 -t ghcr.io/krakjn/timbre:latest - < Dockerfile

.PHONY: help
help:
	@echo "Makefile for timbre project (Zig Build System)"
	@echo ""
	@echo "Targets:"
	@echo "  <no-arg>         - Build for x86_64 with current BUILD_TYPE"
	@echo "  all              - Build for both x86_64 and arm64"
	@echo "  x86_64           - Build for x86_64 with current BUILD_TYPE (default: Debug)" 
	@echo "  arm64            - Build for arm64 with current BUILD_TYPE"
	@echo "  clean            - Clean build artifacts"
	@echo "  deb-x86_64       - Build Debian package for x86_64"
	@echo "  deb-arm64        - Build Debian package for arm64" 
	@echo "  deb              - Build Debian packages for both architectures"
	@echo "  enter            - Enter Docker development container"
	@echo "  install-x86_64   - Install the x86_64 build"
	@echo "  install-arm64    - Install the arm64 build"
	@echo "  uninstall        - Uninstall the current build"
	@echo "  test-x86_64      - Run tests for x86_64 build"
	@echo "  test-arm64       - Run tests for arm64 build"
	@echo "  test             - Run all tests"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_TYPE       - Build type: Debug, Release, or RelWithDebInfo (default: Debug)"
	@echo "  PREFIX           - Installation prefix (default: /usr/local/bin)"
	@echo ""
	@echo "Examples:"
	@echo "  make                          # Build for x86_64 with Debug configuration"
	@echo "  make BUILD_TYPE=Release       # Build for x86_64 with Release configuration"
	@echo "  make arm64                    # Build for arm64 with Debug configuration"
	@echo "  make arm64 BUILD_TYPE=Release # Build for arm64 with Release configuration"
