#!/bin/bash
# Claude Code Complete Uninstaller (Linux/macOS)
# Removes Claude Code CLI, configuration, skills, agents, hooks,
# environment variables, and PATH entries.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Options
KEEP_CONFIG=false
KEEP_ENV_VARS=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-config)    KEEP_CONFIG=true; shift ;;
        --keep-env)       KEEP_ENV_VARS=true; shift ;;
        --force|-f)       FORCE=true; shift ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --keep-config   Keep ~/.claude configuration directory"
            echo "  --keep-env      Keep ANTHROPIC_* environment variables"
            echo "  --force, -f     Skip all confirmation prompts"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Note: When piped (curl | bash), confirmation prompts are auto-accepted."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Detect shell RC file
detect_shell_rc() {
    SHELL_RCS=()
    [ -f "$HOME/.bashrc" ] && SHELL_RCS+=("$HOME/.bashrc")
    [ -f "$HOME/.bash_profile" ] && SHELL_RCS+=("$HOME/.bash_profile")
    [ -f "$HOME/.zshrc" ] && SHELL_RCS+=("$HOME/.zshrc")
    [ -f "$HOME/.profile" ] && SHELL_RCS+=("$HOME/.profile")
    [ -f "$HOME/.config/fish/config.fish" ] && SHELL_RCS+=("$HOME/.config/fish/config.fish")
}

print_header() {
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          Claude Code Uninstaller (Linux/macOS)                ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    local step=$1
    local total=$2
    local message=$3
    echo ""
    echo -e "${CYAN}[$step/$total] $message${NC}"
    echo -e "${GRAY}======================================================================${NC}"
}

print_success() { echo -e "${GREEN}[OK] $1${NC}"; }
print_skip()    { echo -e "${YELLOW}[SKIP] $1${NC}"; }
print_info()    { echo -e "${GRAY}  $1${NC}"; }
print_warn()    { echo -e "${YELLOW}$1${NC}"; }

confirm() {
    if $FORCE; then return 0; fi
    # Auto-confirm if stdin is not a terminal (piped execution)
    if [ ! -t 0 ]; then
        print_info "Non-interactive mode: auto-confirming '$1'"
        return 0
    fi
    read -p "$1 (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Remove Claude CLI
remove_cli() {
    print_step 1 6 "Removing Claude CLI"

    local removed=false

    # Remove native installer binary (~/.local/bin/claude)
    local local_bin="$HOME/.local/bin"
    for f in "$local_bin/claude" "$local_bin/claude-cli"; do
        if [ -f "$f" ]; then
            rm -f "$f"
            print_info "Removed: $f"
            removed=true
        fi
    done

    # Remove any claude-related files in ~/.local/bin
    if [ -d "$local_bin" ]; then
        local claude_files
        claude_files=$(find "$local_bin" -maxdepth 1 -name "claude*" 2>/dev/null || true)
        if [ -n "$claude_files" ]; then
            echo "$claude_files" | while read -r f; do
                rm -f "$f"
                print_info "Removed: $f"
            done
            removed=true
        fi

        # Remove ~/.local/bin if empty
        if [ -d "$local_bin" ] && [ -z "$(ls -A "$local_bin" 2>/dev/null)" ]; then
            rmdir "$local_bin" 2>/dev/null || true
            print_info "Removed empty directory: $local_bin"

            # Remove ~/.local if empty
            if [ -d "$HOME/.local" ] && [ -z "$(ls -A "$HOME/.local" 2>/dev/null)" ]; then
                rmdir "$HOME/.local" 2>/dev/null || true
                print_info "Removed empty directory: $HOME/.local"
            fi
        fi
    fi

    # Check /usr/local/bin
    if [ -f "/usr/local/bin/claude" ]; then
        if [ -w "/usr/local/bin/claude" ] || [ "$(id -u)" -eq 0 ]; then
            rm -f "/usr/local/bin/claude"
            print_info "Removed: /usr/local/bin/claude"
            removed=true
        else
            print_warn "  Found /usr/local/bin/claude but need sudo to remove."
            print_warn "  Run: sudo rm /usr/local/bin/claude"
        fi
    fi

    # Try npm uninstall
    if check_command npm; then
        if npm list -g @anthropic-ai/claude-code 2>/dev/null | grep -q "claude-code"; then
            print_info "Removing npm package @anthropic-ai/claude-code..."
            npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
            print_info "Removed npm package"
            removed=true
        fi
    fi

    if $removed; then
        print_success "Claude CLI removed"
    else
        print_skip "No Claude CLI installation found"
    fi
}

# Step 2: Remove configuration
remove_config() {
    print_step 2 6 "Removing Configuration"

    if $KEEP_CONFIG; then
        print_skip "Keeping configuration (--keep-config)"
        return
    fi

    local config_dir="$HOME/.claude"
    local config_json="$HOME/.claude.json"
    local removed=false

    if [ -d "$config_dir" ]; then
        # Create backup before removal
        local backup_path="$HOME/.claude-uninstall-backup_$(date +%Y%m%d_%H%M%S)"
        print_warn "  Creating backup at: $backup_path"
        cp -r "$config_dir" "$backup_path"

        rm -rf "$config_dir"
        print_info "Removed: $config_dir"
        removed=true
    fi

    if [ -f "$config_json" ]; then
        rm -f "$config_json"
        print_info "Removed: $config_json"
        removed=true
    fi

    if $removed; then
        print_success "Claude configuration removed (backup saved)"
    else
        print_skip "No Claude configuration found"
    fi
}

# Step 3: Remove environment variables from shell RC files
remove_env_vars() {
    print_step 3 6 "Removing Environment Variables"

    if $KEEP_ENV_VARS; then
        print_skip "Keeping environment variables (--keep-env)"
        return
    fi

    detect_shell_rc

    local removed=false

    for rc_file in "${SHELL_RCS[@]}"; do
        if [ -f "$rc_file" ] && grep -q "ANTHROPIC_\|GLM5 API\|API_TIMEOUT_MS" "$rc_file" 2>/dev/null; then
            # Create backup of RC file
            cp "$rc_file" "${rc_file}.pre-uninstall.bak"
            print_info "Backed up: $rc_file"

            if [[ "$rc_file" == *"fish"* ]]; then
                # Fish shell: remove set -gx lines
                sed -i.tmp '/# GLM5 API Configuration/d' "$rc_file"
                sed -i.tmp '/set -gx ANTHROPIC_BASE_URL/d' "$rc_file"
                sed -i.tmp '/set -gx ANTHROPIC_AUTH_TOKEN/d' "$rc_file"
                sed -i.tmp '/set -gx ANTHROPIC_API_KEY/d' "$rc_file"
                sed -i.tmp '/set -gx ANTHROPIC_DEFAULT_/d' "$rc_file"
                sed -i.tmp '/set -gx API_TIMEOUT_MS/d' "$rc_file"
            else
                # Bash/Zsh: remove export lines
                sed -i.tmp '/# GLM5 API Configuration/d' "$rc_file"
                sed -i.tmp '/export ANTHROPIC_BASE_URL/d' "$rc_file"
                sed -i.tmp '/export ANTHROPIC_AUTH_TOKEN/d' "$rc_file"
                sed -i.tmp '/export ANTHROPIC_API_KEY/d' "$rc_file"
                sed -i.tmp '/export ANTHROPIC_DEFAULT_/d' "$rc_file"
                sed -i.tmp '/export API_TIMEOUT_MS/d' "$rc_file"
            fi

            # Remove sed temp files
            rm -f "${rc_file}.tmp"

            print_info "Cleaned: $rc_file"
            removed=true
        fi
    done

    # Unset from current session
    unset ANTHROPIC_BASE_URL 2>/dev/null || true
    unset ANTHROPIC_AUTH_TOKEN 2>/dev/null || true
    unset ANTHROPIC_API_KEY 2>/dev/null || true
    unset ANTHROPIC_DEFAULT_HAIKU_MODEL 2>/dev/null || true
    unset ANTHROPIC_DEFAULT_SONNET_MODEL 2>/dev/null || true
    unset ANTHROPIC_DEFAULT_OPUS_MODEL 2>/dev/null || true
    unset API_TIMEOUT_MS 2>/dev/null || true

    if $removed; then
        print_success "Environment variables removed"
    else
        print_skip "No ANTHROPIC environment variables found in shell configs"
    fi
}

# Step 4: Clean PATH entries from shell RC files
remove_path_entries() {
    print_step 4 6 "Cleaning PATH Entries"

    detect_shell_rc

    local removed=false

    for rc_file in "${SHELL_RCS[@]}"; do
        if [ -f "$rc_file" ] && grep -q '\.local/bin' "$rc_file" 2>/dev/null; then
            # Only remove claude-specific PATH additions, not generic ones
            if grep -q "claude\|Claude" "$rc_file" 2>/dev/null; then
                # Remove Claude-specific PATH lines
                sed -i.tmp '/# Claude Code/d' "$rc_file"
                sed -i.tmp '/# Added by Claude/d' "$rc_file"
                rm -f "${rc_file}.tmp"
                print_info "Cleaned Claude PATH entries from: $rc_file"
                removed=true
            fi
        fi
    done

    if $removed; then
        print_success "PATH entries cleaned"
    else
        print_skip "No Claude PATH entries found"
    fi
}

# Step 5: Remove Claude data directories
remove_data() {
    print_step 5 6 "Removing Data and Cache"

    local removed=false

    # Remove Claude-related XDG data
    local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
    if [ -d "$xdg_data/claude" ]; then
        rm -rf "$xdg_data/claude"
        print_info "Removed: $xdg_data/claude"
        removed=true
    fi

    # Remove Claude-related XDG cache
    local xdg_cache="${XDG_CACHE_HOME:-$HOME/.cache}"
    if [ -d "$xdg_cache/claude" ]; then
        rm -rf "$xdg_cache/claude"
        print_info "Removed: $xdg_cache/claude"
        removed=true
    fi

    # Remove Claude-related XDG config (not ~/.claude, that's handled above)
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    if [ -d "$xdg_config/claude" ]; then
        rm -rf "$xdg_config/claude"
        print_info "Removed: $xdg_config/claude"
        removed=true
    fi

    # Clean npx cache
    if check_command npm; then
        local npm_cache
        npm_cache="$(npm config get cache 2>/dev/null || echo "")"
        if [ -n "$npm_cache" ] && [ -d "$npm_cache/_npx" ]; then
            local claude_npx
            claude_npx=$(find "$npm_cache/_npx" -maxdepth 2 -name "*claude*" -o -name "*anthropic*" 2>/dev/null || true)
            if [ -n "$claude_npx" ]; then
                echo "$claude_npx" | while read -r d; do
                    rm -rf "$d"
                    print_info "Removed npx cache: $(basename "$d")"
                done
                removed=true
            fi
        fi
    fi

    if $removed; then
        print_success "Data and cache cleaned"
    else
        print_skip "No Claude data/cache found"
    fi
}

# Step 6: Verify removal
verify_removal() {
    print_step 6 6 "Verifying Removal"

    local issues=0

    if check_command claude; then
        echo -e "${RED}  [!] claude command still found: $(which claude)${NC}"
        ((issues++))
    else
        print_info "claude command: not found (good)"
    fi

    if [ -d "$HOME/.claude" ] && ! $KEEP_CONFIG; then
        echo -e "${RED}  [!] ~/.claude directory still exists${NC}"
        ((issues++))
    else
        print_info "~/.claude directory: removed"
    fi

    if [ -n "${ANTHROPIC_BASE_URL:-}" ] && ! $KEEP_ENV_VARS; then
        echo -e "${RED}  [!] ANTHROPIC_BASE_URL still set in current session${NC}"
        print_info "  (will be gone after terminal restart)"
    fi

    if [ $issues -eq 0 ]; then
        print_success "Verification passed"
    else
        print_warn "  $issues issue(s) found - see above"
    fi
}

# Main
main() {
    print_header

    echo -e "${YELLOW}This will remove the following:${NC}"
    echo "  - Claude Code CLI (native binary and/or npm package)"
    if ! $KEEP_CONFIG; then
        echo "  - Configuration directory (~/.claude)"
        echo "  - MCP configuration (~/.claude.json)"
        echo "  - Skills, agents, and hooks"
    fi
    if ! $KEEP_ENV_VARS; then
        echo "  - ANTHROPIC_* environment variables from shell configs"
    fi
    echo "  - PATH entries added by installer"
    echo "  - Cache and data directories"
    echo ""

    if ! confirm "Are you sure you want to uninstall Claude Code?"; then
        echo -e "${YELLOW}Uninstall cancelled.${NC}"
        exit 0
    fi

    remove_cli
    remove_config
    remove_env_vars
    remove_path_entries
    remove_data
    verify_removal

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Uninstall Complete                                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Claude Code has been removed from this system.${NC}"

    if ! $KEEP_CONFIG; then
        echo ""
        echo -e "${YELLOW}A backup of your configuration was saved to:${NC}"
        local backups
        backups=$(find "$HOME" -maxdepth 1 -name ".claude-uninstall-backup_*" -type d 2>/dev/null || true)
        if [ -n "$backups" ]; then
            echo "$backups" | while read -r b; do
                echo "  $b"
            done
            echo ""
            echo -e "${GRAY}Delete the backup manually when you no longer need it.${NC}"
        fi
    fi

    echo ""
    echo -e "${YELLOW}Please restart your terminal for all changes to take effect.${NC}"
}

main "$@"
