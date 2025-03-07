#  ______   __     __    __     ______     ______     ______    
# /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\   
# \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\   
#    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\ 
#     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/ 
                                                              
BUILD_TYPE ?= Debug
PREFIX ?= /usr/local/bin
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# Default architecture is native
ARCH ?= amd64

# Compiler settings based on architecture
ifeq ($(ARCH),arm64)
    CXX = aarch64-linux-gnu-g++
    CC = aarch64-linux-gnu-gcc
    ARCH_FLAGS = -DCMAKE_SYSTEM_PROCESSOR=aarch64
else
    CXX = g++
    CC = gcc
    ARCH_FLAGS = -DCMAKE_SYSTEM_PROCESSOR=x86_64
endif

BUILD_DIR = build-$(ARCH)

.PHONY: default
default: $(BUILD_DIR)
	@cmake --build $(BUILD_DIR) -- -j$(NPROC)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake .. \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(PREFIX) \
		$(ARCH_FLAGS)

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

.PHONY: deb
deb: $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake --build . --target package

.PHONY: enter
enter:
	@docker run -it --rm \
		-v $(PWD):/app \
		-w /app \
		--hostname timbre \
		ghcr.io/krakjn/timbre:latest

.PHONY: install
install: all
	@echo "Installing to $(PREFIX)..."
	@cmake --install $(BUILD_DIR)

.PHONY: uninstall
uninstall:
	@if [ -f "$(BUILD_DIR)/install_manifest.txt" ]; then \
		xargs rm -f < "$(BUILD_DIR)/install_manifest.txt"; \
	else \
		echo "No install manifest found. Cannot uninstall automatically."; \
		exit 1; \
	fi

.PHONY: test
test:
	@cd $(BUILD_DIR) && ctest --output-on-failure

.PHONY: help
help:
	@echo "Makefile for timbre project"
	@echo ""
	@echo "Targets:"
	@echo "  <no arg>   - Build the project (default)"
	@echo "  clean      - Clean build artifacts"
	@echo "  deb        - Build Debian package"
	@echo "  enter      - Enter Docker container"
	@echo "  install    - Install the project to PREFIX (default: /usr/local)"
	@echo "  uninstall  - Uninstall the project"
	@echo "  test       - Build and run the tests"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  BUILD_TYPE - Build type: Debug or Release (default: Debug)"
	@echo "  PREFIX     - Installation prefix (default: /usr/local)"
	@echo ""
	@echo "Examples:"
	@echo "  make                      # Build with default settings"
	@echo "  make BUILD_TYPE=Release   # Build in Release mode"
	@echo "  make install PREFIX=~/bin # Install to ~/bin"

