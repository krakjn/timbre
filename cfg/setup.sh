#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

PROJECT_ROOT=$(git rev-parse --show-toplevel)

echo -e "${YELLOW}Setting up Git hooks for commit message linting...${RESET}"

mkdir -p "$PROJECT_ROOT/.githooks"

# Create commit-msg hook
cat > "$PROJECT_ROOT/.githooks/commit-msg" << 'HOOK'
#!/bin/bash

# Get the commit message file
COMMIT_MSG_FILE=$1

# script is ran in top level git directory

# Check if commitlint is available locally
if command -v commitlint &> /dev/null; then
    # Use local commitlint installation with config from cfg directory
    cat $COMMIT_MSG_FILE | commitlint --config "cfg/commitlintrc.json"
    EXIT_CODE=$?
else
    echo -e "\033[1;33mWarning: commitlint not found locally.\033[0m"
    echo -e "Please either:"
    echo -e "1. Install commitlint globally: npm install -g @commitlint/cli @commitlint/config-conventional"
    echo -e "2. Use the timbre development container: docker run -it --rm -v \$(pwd):/app ghcr.io/ballast-dev/timbre:latest"
    echo -e "\nFalling back to basic regex validation...\n"
    
    # Simple regex-based commit message validation
    COMMIT_MSG=$(cat $COMMIT_MSG_FILE)
    PATTERN='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9 -]+\))?(!)?: .+$'
    
    if [[ $COMMIT_MSG =~ $PATTERN ]]; then
        EXIT_CODE=0
    else
        EXIT_CODE=1
        echo "Error: Commit message does not follow conventional commit format."
    fi
fi

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "Commit message format examples:"
    echo "  feat: add new feature"
    echo "  fix: resolve bug"
    echo "  docs: update documentation"
    echo "  style: format code"
    echo "  refactor: restructure code"
    echo "  test: add tests"
    echo "  chore: update dependencies"
    echo ""
    echo "For more details, see: https://www.conventionalcommits.org/"
    exit $EXIT_CODE
fi

exit 0
HOOK

chmod +x "$PROJECT_ROOT/.githooks/commit-msg"
cd "$PROJECT_ROOT" && git config core.hooksPath .githooks
echo -e "${GREEN}Git hooks setup complete!${RESET}"

if ! command -v commitlint &> /dev/null; then
    echo -e "${YELLOW}Note: commitlint is not installed locally.${RESET}"
    echo -e "For the best experience, please either:"
    echo -e "1. Install commitlint globally:"
    echo -e "   ${GREEN}npm install -g @commitlint/cli @commitlint/config-conventional${RESET}"
    echo -e "2. Use the timbre development container:"
    echo -e "   ${GREEN}docker run -it --rm -v \$(pwd):/app ghcr.io/ballast-dev/timbre:latest${RESET}"
    echo -e "\nThe hook will use a basic regex validation until commitlint is available."
else
    echo -e "${GREEN}commitlint is installed and ready to use.${RESET}"
fi
