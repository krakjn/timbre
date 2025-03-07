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
BUILD_X86_64 = build_x86_64
BUILD_ARM64 = build_arm64

# Configure cross-config settings
CROSS_CONFIGS = all

.PHONY: default
default: configure-x86_64
	@echo "Building $(BUILD_TYPE) configuration for x86_64"
	@cmake --build $(BUILD_X86_64) --config $(BUILD_TYPE) -j$(NPROC)

.PHONY: configure-x86_64
configure-x86_64:
	@mkdir -p $(BUILD_X86_64)
	@cd $(BUILD_X86_64) && cmake .. \
		-G "Ninja Multi-Config" \
		-DCMAKE_CONFIGURATION_TYPES="Debug;Release;RelWithDebInfo" \
		-DCMAKE_DEFAULT_BUILD_TYPE="$(BUILD_TYPE)" \
		-DCMAKE_CROSS_CONFIGS="$(CROSS_CONFIGS)" \
		-DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain.cmake \
		-DTARGET_ARCH=x86_64

.PHONY: cross
cross: configure-arm64
	@echo "Building $(BUILD_TYPE) configuration for arm64"
	@cmake --build $(BUILD_ARM64) --config $(BUILD_TYPE) -j$(NPROC)

.PHONY: configure-arm64
configure-arm64:
	@mkdir -p $(BUILD_ARM64)
	@cd $(BUILD_ARM64) && cmake .. \
		-G "Ninja Multi-Config" \
		-DCMAKE_CONFIGURATION_TYPES="Debug;Release;RelWithDebInfo" \
		-DCMAKE_DEFAULT_BUILD_TYPE="$(BUILD_TYPE)" \
		-DCMAKE_CROSS_CONFIGS="$(CROSS_CONFIGS)" \
		-DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain.cmake \
		-DTARGET_ARCH=arm64

.PHONY: all
all: default cross

.PHONY: clean
clean:
	@rm -rf $(BUILD_X86_64) $(BUILD_ARM64)

.PHONY: deb
deb: default
	@cd $(BUILD_X86_64) && cmake --build . --config $(BUILD_TYPE) --target package

.PHONY: deb-cross
deb-cross: cross
	@cd $(BUILD_ARM64) && cmake --build . --config $(BUILD_TYPE) --target package

.PHONY: deb-all
deb-all: deb deb-cross

.PHONY: enter
enter:
	@docker run -it --rm \
		-v $(PWD):/app \
		-w /app \
		--hostname timbre \
		ghcr.io/krakjn/timbre:latest

.PHONY: install
install: default
	@echo "Installing $(BUILD_TYPE) configuration to $(PREFIX)..."
	@cmake --install $(BUILD_X86_64) --config $(BUILD_TYPE)

.PHONY: install-cross
install-cross: cross
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

.PHONY: test
test: default
	@cd $(BUILD_X86_64) && ctest --output-on-failure -C $(BUILD_TYPE)

.PHONY: help
help:
	@echo "Makefile for timbre project (Ninja Multi-Config Build System)"
	@echo ""
	@echo "Targets:"
	@echo "  <no arg>      - Build for x86_64 with current BUILD_TYPE (default: Debug)"
	@echo "  cross         - Build for arm64 with current BUILD_TYPE"
	@echo "  all           - Build for both x86_64 and arm64"
	@echo "  clean         - Clean build artifacts"
	@echo "  deb           - Build Debian package for x86_64"
	@echo "  deb-cross     - Build Debian package for arm64"
	@echo "  deb-all       - Build Debian packages for both architectures"
	@echo "  enter         - Enter Docker container"
	@echo "  install       - Install the x86_64 build"
	@echo "  install-cross - Install the arm64 build"
	@echo "  uninstall     - Uninstall the current build"
	@echo "  test          - Run tests (x86_64 only)"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_TYPE   - Build type: Debug, Release, or RelWithDebInfo (default: Debug)"
	@echo "  PREFIX       - Installation prefix (default: /usr/local/bin)"
	@echo ""
	@echo "Examples:"
	@echo "  make                      # Build for x86_64 with Debug configuration"
	@echo "  make BUILD_TYPE=Release   # Build for x86_64 with Release configuration"
	@echo "  make cross                # Build for arm64 with Debug configuration"
	@echo "  make cross BUILD_TYPE=Release # Build for arm64 with Release configuration"

