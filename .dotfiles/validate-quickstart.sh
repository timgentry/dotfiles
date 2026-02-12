#!/usr/bin/env bash
# Validation script for quickstart.md scenarios
# Tests that all installation and verification steps work as documented

set -euo pipefail

# Colors for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_SUCCESS='\033[0;32m'
readonly COLOR_ERROR='\033[0;31m'
readonly COLOR_INFO='\033[0;36m'

passed_tests=0
failed_tests=0

test_pass() {
    echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $1"
    passed_tests=$((passed_tests + 1))
}

test_fail() {
    echo -e "${COLOR_ERROR}✗${COLOR_RESET} $1"
    failed_tests=$((failed_tests + 1))
}

test_info() {
    echo -e "${COLOR_INFO}→${COLOR_RESET} $1"
}

echo "=================================="
echo "  Quickstart Validation"
echo "=================================="
echo ""

# Test 1: Check if Homebrew is installed
test_info "Checking Homebrew installation..."
if command -v brew &>/dev/null; then
    test_pass "Homebrew is installed"
else
    test_fail "Homebrew is not installed"
fi

# Test 2: Check if GNU Stow is installed
test_info "Checking GNU Stow installation..."
if command -v stow &>/dev/null; then
    test_pass "GNU Stow is installed"
else
    test_fail "GNU Stow is not installed"
fi

# Test 3: Check if Brewfile packages are installed
test_info "Checking Brewfile packages..."
if [ -f "$HOME/.dotfiles/Brewfile" ]; then
    cd "$HOME/.dotfiles"
    if brew bundle check &>/dev/null; then
        test_pass "All Brewfile packages are installed"
    else
        test_fail "Some Brewfile packages are missing"
    fi
else
    test_fail "Brewfile not found"
fi

# Test 4: Check configuration symlinks
test_info "Checking configuration symlinks..."
for config in .zshrc .zprofile .gitconfig .gemrc; do
    if [ -L "$HOME/$config" ]; then
        test_pass "~/$config is symlinked"
    else
        test_fail "~/$config is not symlinked"
    fi
done

# Test 5: Check bin directory symlink
test_info "Checking ~/bin symlink..."
if [ -L "$HOME/bin" ]; then
    test_pass "~/bin is symlinked"
else
    test_fail "~/bin is not symlinked"
fi

# Test 6: Check PATH includes ~/bin
test_info "Checking PATH configuration..."
if echo "$PATH" | grep -q "$HOME/bin"; then
    test_pass "~/bin is in PATH"
else
    test_fail "~/bin is not in PATH (you may need to restart your shell)"
fi

# Test 7: Check utility scripts are executable
test_info "Checking utility scripts..."
if [ -x "$HOME/bin/gh-open" ]; then
    test_pass "gh-open is executable"
else
    test_fail "gh-open is not executable or not found"
fi

# Test 8: Check state file exists
test_info "Checking installation state..."
if [ -f "$HOME/.dotfiles_state" ]; then
    test_pass "State file exists"
else
    test_fail "State file not found"
fi

# Test 9: Check log file exists
test_info "Checking setup log..."
if [ -f "$HOME/.dotfiles/setup.log" ]; then
    test_pass "Setup log exists"
else
    test_fail "Setup log not found"
fi

# Summary
echo ""
echo "=================================="
echo "  Summary"
echo "=================================="
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"

if [ $failed_tests -eq 0 ]; then
    echo -e "${COLOR_SUCCESS}All tests passed!${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_ERROR}Some tests failed.${COLOR_RESET}"
    exit 1
fi
