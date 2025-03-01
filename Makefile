#  ______   __     __    __     ______     ______     ______    
# /\__  _\ /\ \   /\ "-./  \   /\  == \   /\  == \   /\  ___\   
# \/_/\ \/ \ \ \  \ \ \-./\ \  \ \  __<   \ \  __<   \ \  __\   
#    \ \_\  \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\ \_\  \ \_____\ 
#     \/_/   \/_/   \/_/  \/_/   \/_____/   \/_/ /_/   \/_____/ 
                                                              
BUILD_TYPE ?= Debug
BUILD_DIR = build
PREFIX ?= /usr/local/bin
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)

# Default target is first target
.PHONY: all
all: $(BUILD_DIR)
	@echo "Building timbre ($(BUILD_TYPE))..."
	@cmake --build $(BUILD_DIR) -- -j$(NPROC)

$(BUILD_DIR):
	@echo "Creating build directory and generating build files..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && cmake .. -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_INSTALL_PREFIX=$(PREFIX)

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@if [ -d "$(BUILD_DIR)" ]; then cmake --build $(BUILD_DIR) --target clean; fi

.PHONY: distclean
distclean:
	@echo "Removing build directory..."
	@rm -rf $(BUILD_DIR)

.PHONY: install
install: all
	@echo "Installing to $(PREFIX)..."
	@cmake --install $(BUILD_DIR)

.PHONY: uninstall
uninstall:
	@echo "Uninstalling..."
	@if [ -f "$(BUILD_DIR)/install_manifest.txt" ]; then \
		xargs rm -f < "$(BUILD_DIR)/install_manifest.txt"; \
	else \
		echo "No install manifest found. Cannot uninstall automatically."; \
		exit 1; \
	fi

.PHONY: test
test:
	@cd $(BUILD_DIR) && ctest

.PHONY: run
run: all
	@$(BUILD_DIR)/timbre

.PHONY: help
help:
	@echo "Makefile for timbre project"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build the project (default)"
	@echo "  clean      - Clean build artifacts"
	@echo "  install    - Install the project to PREFIX (default: /usr/local)"
	@echo "  uninstall  - Uninstall the project"
	@echo "  run        - Build and run the executable"
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

