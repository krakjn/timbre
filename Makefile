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
BUILD_X86_64 = build/x86_64
BUILD_ARM64 = build/arm64

# Default target is x86_64, as most users will be on Intel/AMD
.PHONY: default
default: x86_64 

$(BUILD_X86_64):
	@cmake -S . -B $(BUILD_X86_64) -G "Ninja Multi-Config" \
		-DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_x86_64.cmake \
		-DCMAKE_CONFIGURATION_TYPES="Debug;Release;RelWithDebInfo"

$(BUILD_ARM64):
	@cmake -S . -B $(BUILD_ARM64) -G "Ninja Multi-Config" \
		-DCMAKE_TOOLCHAIN_FILE=cmake/toolchain_arm64.cmake \
		-DCMAKE_CONFIGURATION_TYPES="Debug;Release;RelWithDebInfo"

.PHONY: x86_64
x86_64: $(BUILD_X86_64)
	@cmake --build $(BUILD_X86_64) --config $(BUILD_TYPE) -j$(NPROC)

.PHONY: arm64
arm64: $(BUILD_ARM64)
	@cmake --build $(BUILD_ARM64) --config $(BUILD_TYPE) -j$(NPROC)

.PHONY: all
all: x86_64 arm64

.PHONY: clean
clean:
	@rm -rf $(BUILD_X86_64) $(BUILD_ARM64)

.PHONY: deb-x86_64
deb-x86_64: x86_64
	@cd $(BUILD_X86_64) && cmake --build . --config $(BUILD_TYPE) --target package

.PHONY: deb-arm64
deb-arm64: arm64
	@cd $(BUILD_ARM64) && cmake --build . --config $(BUILD_TYPE) --target package

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
	@cmake --install $(BUILD_X86_64) --config $(BUILD_TYPE)

.PHONY: install-arm64
install-arm64: arm64
	@echo "Installing $(BUILD_TYPE) configuration for arm64..."
	@cmake --install $(BUILD_ARM64) --config $(BUILD_TYPE)

.PHONY: uninstall
uninstall:
	@if [ -f "$(BUILD_X86_64)/install_manifest_$(BUILD_TYPE).txt" ]; then \
		xargs rm -f < "$(BUILD_X86_64)/install_manifest_$(BUILD_TYPE).txt"; \
	else \
		echo "No install manifest found for $(BUILD_TYPE). Cannot uninstall automatically."; \
		exit 1; \
	fi

.PHONY: test-x86_64
test-x86_64: x86_64
	@cd $(BUILD_X86_64) && ctest --output-on-failure -C $(BUILD_TYPE)

.PHONY: test-arm64
test-arm64: arm64
	@echo "Skipping arm tests on non-arm platform"

.PHONY: test
test: test-x86_64 test-arm64

# Build the Docker image without context
.PHONY: docker-build
docker-build:
	@docker build --platform linux/amd64 -t ghcr.io/krakjn/timbre:latest - < Dockerfile

.PHONY: help
help:
	@echo "Makefile for timbre project (Ninja Multi-Config Build System)"
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
