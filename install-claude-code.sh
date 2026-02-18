#!/bin/bash
# Claude Code CLI Installer with GLM5 Configuration
# Linux/macOS version

set -e

# Parse command line arguments
ASSUME_YES=false
for arg in "$@"; do
    case $arg in
        -y|--yes|--assume-yes)
            ASSUME_YES=true
            shift
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MODEL="${MODEL:-glm5}"
CONFIG_DIR="$HOME/.claude"
SHELL_RC="$HOME/.bashrc"

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$FISH_VERSION" ]; then
    SHELL_RC="$HOME/.config/fish/config.fish"
fi

print_header() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     Claude Code Installer - GLM5 Edition (Linux/macOS)        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes, --assume-yes    Run non-interactively, accept all defaults"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MODEL                      Model to configure (default: glm5)"
    echo "  ANTHROPIC_AUTH_TOKEN       Pre-configured API key"
    echo ""
    echo "Examples:"
    echo "  curl -fsSL <url> | bash              # Interactive install"
    echo "  curl -fsSL <url> | bash -s -- -y     # Non-interactive install"
    echo "  ANTHROPIC_AUTH_TOKEN=x.x $0 -y       # With pre-set API key"
    exit 0
}

# Check for help flag
for arg in "$@"; do
    case $arg in
        -h|--help)
            print_header
            show_usage
            ;;
    esac
done

print_step() {
    local step=$1
    local total=$2
    local message=$3
    echo ""
    echo -e "${CYAN}[$step/$total] $message${NC}"
    echo -e "${GRAY}======================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Prompt user with default - returns 0 for yes, 1 for no
# Auto-accepts if ASSUME_YES is true or stdin is not a terminal
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-Y}"  # Default to Yes

    if [ "$ASSUME_YES" = true ]; then
        return 0
    fi

    # Check if stdin is a terminal
    if [ ! -t 0 ]; then
        print_info "Non-interactive mode: auto-accepting '$prompt'"
        return 0
    fi

    local reply
    read -p "$prompt ($default/n) " -n 1 -r
    echo

    if [ -z "$REPLY" ]; then
        REPLY="$default"
    fi

    [[ $REPLY =~ ^[Yy]$ ]]
}

# Prompt for input with default value
prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ "$ASSUME_YES" = true ] && [ -n "$default" ]; then
        eval "$var_name=\"$default\""
        return
    fi

    # Check if stdin is a terminal
    if [ ! -t 0 ]; then
        print_info "Non-interactive mode: using default for '$prompt'"
        eval "$var_name=\"$default\""
        return
    fi

    local input
    read -p "$prompt [$default]: " input
    if [ -z "$input" ]; then
        input="$default"
    fi
    eval "$var_name=\"$input\""
}

# Helper functions
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_info "Backed up: $file → $backup"
    fi
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Check prerequisites
check_prerequisites() {
    print_step 1 8 "Checking Prerequisites"

    local missing=0

    # Check for npm/node
    if check_command npm; then
        print_success "npm found: $(npm --version)"
    else
        print_error "npm not found"
        print_info "Install Node.js from https://nodejs.org/ or via your package manager"
        missing=1
    fi

    # Check for git
    if check_command git; then
        print_success "git found: $(git --version)"
    else
        print_error "git not found"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        print_error "Missing prerequisites. Please install them and run again."
        exit 1
    fi
}

# Step 2: Install Claude Code CLI
install_claude_cli() {
    print_step 2 8 "Installing Claude Code CLI"

    if check_command claude; then
        local current_version=$(claude --version 2>&1 || echo "unknown")
        print_success "Claude CLI already installed: $current_version"

        if prompt_yes_no "Update to latest version?" "N"; then
            print_info "Updating Claude CLI..."
            claude update
            print_success "Claude CLI updated"
        fi
    else
        print_info "Installing Claude CLI via native installer (recommended)..."
        print_info "Running: curl -fsSL https://claude.ai/install.sh | bash"

        # Use the official native installer (npm installation is deprecated)
        if curl -fsSL https://claude.ai/install.sh | bash; then
            print_success "Claude CLI installed via native installer"
        else
            print_warning "Native installer failed, trying npm fallback (deprecated)..."
            if check_command npm; then
                npm install -g @anthropic-ai/claude-code
                print_success "Claude CLI installed via npm (deprecated method)"
            else
                print_error "npm not found. Please install Node.js or fix network issues"
                exit 1
            fi
        fi
    fi
}

# Step 3: Configure GLM5 API
configure_glm5_api() {
    print_step 3 8 "Configuring GLM5 API"

    local api_url="https://api.z.ai/api/anthropic"
    local api_key=""

    # Check for existing env vars
    if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
        print_success "Found API key in ANTHROPIC_AUTH_TOKEN"
        if prompt_yes_no "Use existing API key?" "Y"; then
            api_key="$ANTHROPIC_AUTH_TOKEN"
        fi
    fi

    # Prompt for API key if not using existing
    if [ -z "$api_key" ]; then
        echo ""
        print_info "GLM5 API Configuration"
        print_info "API Endpoint: $api_url"
        echo ""

        # Check if running interactively
        if [ -t 0 ]; then
            read -p "Enter your GLM5 API key (format: id.secret): " api_key
        else
            print_warning "Non-interactive mode: API key not provided."
            print_info "Set ANTHROPIC_AUTH_TOKEN environment variable before running, or run interactively."
            api_key="YOUR_GLM5_API_KEY_HERE"
        fi

        if [ -z "$api_key" ]; then
            print_warning "No API key provided. You'll need to configure it manually."
            api_key="YOUR_GLM5_API_KEY_HERE"
        fi
    fi

    # Set environment variables permanently
    echo ""
    if prompt_yes_no "Set GLM5 environment variables permanently?" "Y"; then
        # Determine shell and add to appropriate rc file
        local env_export=""
        local fish_syntax=""

        if [[ "$SHELL_RC" == *"fish"* ]]; then
            # Fish shell syntax
            fish_syntax="
# GLM5 API Configuration
set -gx ANTHROPIC_BASE_URL $api_url
set -gx ANTHROPIC_AUTH_TOKEN $api_key
"
            # Add to fish config
            if ! grep -q "ANTHROPIC_BASE_URL" "$SHELL_RC" 2>/dev/null; then
                echo "$fish_syntax" >> "$SHELL_RC"
                print_success "Added to $SHELL_RC (Fish shell)"
            fi
            # Set for current session (fish)
            set -gx ANTHROPIC_BASE_URL "$api_url"
            set -gx ANTHROPIC_AUTH_TOKEN "$api_key"
        else
            # Bash/Zsh syntax
            env_export="

# GLM5 API Configuration
export ANTHROPIC_BASE_URL=\"$api_url\"
export ANTHROPIC_AUTH_TOKEN=\"$api_key\"
"
            # Add to shell rc
            if ! grep -q "ANTHROPIC_BASE_URL" "$SHELL_RC" 2>/dev/null; then
                echo "$env_export" >> "$SHELL_RC"
                print_success "Added to $SHELL_RC"
            else
                print_info "Environment variables already exist in $SHELL_RC"
            fi

            # Set for current session
            export ANTHROPIC_BASE_URL="$api_url"
            export ANTHROPIC_AUTH_TOKEN="$api_key"
        fi

        print_success "Environment variables configured"
        print_info "Source $SHELL_RC or restart your shell to use in new sessions"
    else
        # Set for current session only
        export ANTHROPIC_BASE_URL="$api_url"
        export ANTHROPIC_AUTH_TOKEN="$api_key"
        print_info "Environment variables set for current session only"
    fi

    # Store for config file
    API_URL_STORE="$api_url"
    API_KEY_STORE="$api_key"
}

# Step 4: Create configuration directory and files
create_config() {
    print_step 4 8 "Creating Configuration"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/hooks"
    mkdir -p "$CONFIG_DIR/skills"
    mkdir -p "$CONFIG_DIR/agents"
    mkdir -p "$CONFIG_DIR/backups"
    mkdir -p "$CONFIG_DIR/logs"

    # Create settings.json with GLM5 environment configuration
    # GLM5 requires specific env variables as per https://aiengineerguide.com/blog/glm-5-in-claude-code/
    cat > "$CONFIG_DIR/settings.json" << EOF
{
  "_comment": "Claude Code Configuration - GLM5 via Zhipu AI proxy",
  "_comment2": "GLM5 API: https://api.z.ai/api/anthropic (Zhipu AI proxy)",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$API_KEY_STORE",
    "ANTHROPIC_BASE_URL": "$API_URL_STORE",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
  },
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allowedTools": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "Task(*)",
      "TaskOutput(*)",
      "TaskStop(*)",
      "NotebookEdit(*)",
      "WebSearch(*)",
      "WebFetch(*)",
      "AskUserQuestion(*)",
      "Skill(*)",
      "EnterPlanMode(*)",
      "ExitPlanMode(*)",
      "TodoWrite(*)"
    ],
    "deniedTools": [],
    "askBeforeUse": []
  },
  "agentOrchestration": {
    "enabled": true,
    "mode": "always",
    "defaultAgent": "task-manager",
    "agentSelectionStrategy": "automatic",
    "fallbackToDirect": false,
    "minTaskComplexity": 1,
    "preferSpecializedAgents": true,
    "allowAgentChaining": true,
    "maxConcurrentAgents": 5,
    "coordinationTimeout": 300000
  },
  "deleteProtection": {
    "enabled": true,
    "confirmBeforeDelete": true,
    "protectedPaths": [
      "~/.claude",
      "~/projects",
      "~/projects"
    ],
    "requireConfirmationFor": [
      "Bash",
      "Edit",
      "Write"
    ],
    "deleteCommands": [
      "rm",
      "rmdir",
      "del",
      "git clean"
    ]
  },
  "uiPreferences": {
    "theme": "dark",
    "fontSize": 14,
    "tabSize": 2,
    "showLineNumbers": true,
    "wordWrap": true,
    "showAgentActivity": true,
    "showTaskProgress": true
  },
  "featureFlags": {
    "thinkingMode": true,
    "planMode": true,
    "streaming": true,
    "autoSave": true,
    "autoAgentMode": true,
    "multiAgentCoordination": true
  },
  "advanced": {
    "maxTokens": 8192,
    "temperature": 0.7,
    "cacheEnabled": true,
    "debugMode": false,
    "agentDebugEnabled": true
  },
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/pre-tool.sh"
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/post-tool.sh"
      }
    ]
  }
}
EOF

    print_success "Created: $CONFIG_DIR/settings.json"
}

# Step 5: Create hooks
create_hooks() {
    print_step 5 8 "Creating Agent-First Hooks"

    # Create pre-prompt hook
    cat > "$CONFIG_DIR/hooks/pre-prompt.sh" << 'EOF'
#!/bin/bash
# Claude Code Pre-Prompt Hook
# This hook runs before every user prompt and enforces agent-first workflow

HOOKS_CONFIG="$HOME/.claude/hooks/hooks.json"

if [ -f "$HOOKS_CONFIG" ]; then
    AGENT_ENABLED=$(jq -r '.hooks["Notification"].enabled' "$HOOKS_CONFIG" 2>/dev/null || echo "false")

    if [ "$AGENT_ENABLED" = "true" ]; then
        # Agent instruction will be added by the system
        # This is a placeholder for future enhancements
        :
    fi
fi
EOF

    chmod +x "$CONFIG_DIR/hooks/pre-prompt.sh"
    print_success "Created: $CONFIG_DIR/hooks/pre-prompt.sh"

    # Create pre-tool hook for delete protection
    cat > "$CONFIG_DIR/hooks/pre-tool.sh" << 'EOF'
#!/bin/bash
# Claude Code Pre-Tool Hook
# This hook runs before every tool use and protects against destructive operations

TOOL_NAME="$1"
shift

# Check for destructive operations
case "$TOOL_NAME" in
    "Bash"|"Write"|"Edit")
        # Check command for delete patterns
        for arg in "$@"; do
            case "$arg" in
                *rm*|*rmdir*|*del*|*Remove-Item*|*git\ clean*)
                    echo "⚠️  DESTRUCTIVE OPERATION DETECTED"
                    echo "This operation will: $*"
                    echo ""
                    echo "To proceed, you must:"
                    echo "1. Acknowledge this is a destructive operation"
                    echo "2. Confirm you understand the consequences"
                    echo "3. Request explicit user permission"
                    exit 1
                    ;;
            esac
        done
        ;;
esac

exit 0
EOF

    chmod +x "$CONFIG_DIR/hooks/pre-tool.sh"
    print_success "Created: $CONFIG_DIR/hooks/pre-tool.sh"

    # Create post-tool hook for logging
    cat > "$CONFIG_DIR/hooks/post-tool.sh" << 'EOF'
#!/bin/bash
# Claude Code Post-Tool Hook
# This hook runs after every tool use and logs operations

TOOL_NAME="$1"
LOG_FILE="$HOME/.claude/logs/operations.log"
TIMESTAMP=$(date -Iseconds)

mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TIMESTAMP] Tool: $TOOL_NAME" >> "$LOG_FILE"
EOF

    chmod +x "$CONFIG_DIR/hooks/post-tool.sh"
    print_success "Created: $CONFIG_DIR/hooks/post-tool.sh"
}

# Step 6: Create hooks configuration
create_hooks_config() {
    print_step 6 8 "Creating Hooks Configuration"

    cat > "$CONFIG_DIR/hooks/hooks.json" << 'EOF'
{
  "_comment": "Claude Code Hooks Configuration - Enforces Agent-First Workflow",
  "version": "1.0.0",
  "enabled": true,
  "hooks": {
    "Notification": {
      "enabled": true,
      "handler": "agent-orchestrator",
      "config": {
        "forceAgentUsage": true,
        "minComplexityThreshold": 1,
        "excludeSimpleTasks": false,
        "defaultAgents": [
          "task-manager",
          "project-navigator",
          "frontend-developer",
          "backend-architect",
          "test-writer-fixer"
        ],
        "agentSelection": "automatic",
        "allowDirectExecution": false,
        "requireApprovalForDirect": true
      }
    },
    "PreToolUse": {
      "enabled": true,
      "handler": "delete-protector",
      "config": {
        "protectedOperations": ["Write", "Edit", "Bash"],
        "deletePatterns": ["rm", "rmdir", "del", "Remove-Item", "git clean"],
        "protectedPaths": ["~/.claude", "~/projects"],
        "requireConfirmation": true,
        "backupBeforeDelete": true,
        "backupLocation": "~/.claude/backups"
      }
    },
    "PostToolUse": {
      "enabled": true,
      "handler": "operation-logger",
      "config": {
        "logAllOperations": true,
        "logFile": "~/.claude/logs/operations.log",
        "logLevel": "info",
        "includeTimestamp": true,
        "includeToolResult": true
      }
    }
  }
}
EOF

    print_success "Created: $CONFIG_DIR/hooks/hooks.json"
}

# Step 7: Copy skills and agents from installer directory
copy_skills_agents() {
    print_step 7 8 "Installing Skills and Agents"

    INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Copy skills
    if [ -d "$INSTALLER_DIR/skills" ]; then
        cp -r "$INSTALLER_DIR/skills"/* "$CONFIG_DIR/skills/" 2>/dev/null || true
        print_success "Skills installed to $CONFIG_DIR/skills/"
    fi

    # Copy agents
    if [ -d "$INSTALLER_DIR/agents" ]; then
        cp -r "$INSTALLER_DIR/agents"/* "$CONFIG_DIR/agents/" 2>/dev/null || true
        print_success "Agents installed to $CONFIG_DIR/agents/"
    fi
}

# Step 8: Test installation
test_installation() {
    print_step 8 8 "Testing Installation"

    local passed=0
    local failed=0

    # Test CLI
    if check_command claude; then
        print_success "Claude CLI available"
        ((passed++))
    else
        print_error "Claude CLI not found"
        ((failed++))
    fi

    # Test config
    if [ -f "$CONFIG_DIR/settings.json" ]; then
        print_success "Configuration file exists"
        ((passed++))
    else
        print_error "Configuration file missing"
        ((failed++))
    fi

    # Test env vars
    if [ -n "$ANTHROPIC_BASE_URL" ] && [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
        print_success "Environment variables set"
        ((passed++))
    else
        print_warning "Environment variables not set in current session"
        print_info "Source $SHELL_RC or restart shell"
    fi

    # Test hooks
    if [ -f "$CONFIG_DIR/hooks/pre-prompt.sh" ]; then
        print_success "Hooks installed"
        ((passed++))
    else
        print_error "Hooks missing"
        ((failed++))
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Tests Passed: $passed"
    echo "Tests Failed: $failed"
    echo ""

    if [ $failed -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_warning "Some tests failed. Check the output above."
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Next Steps${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Restart your shell or run:"
    echo -e "   ${GREEN}source $SHELL_RC${NC}"
    echo ""
    echo "2. Verify installation:"
    echo -e "   ${GREEN}claude --version${NC}"
    echo ""
    echo "3. Test GLM5:"
    echo -e "   ${GREEN}claude --model glm5 \"Say hello\"${NC}"
    echo ""
    echo "4. Check environment variables:"
    echo -e "   ${GREEN}echo \$ANTHROPIC_BASE_URL${NC}"
    echo -e "   ${GREEN}echo \$ANTHROPIC_AUTH_TOKEN${NC}"
    echo ""
    echo "5. For more information, see:"
    echo -e "   ${GREEN}docs/GLM5-SETUP.md${NC}"
    echo "   ${GREEN}docs/AGENT-FIRST-WORKFLOW.md${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Main installation flow
main() {
    print_header

    print_info "Installation Configuration:"
    echo "  Model: $MODEL"
    echo "  Config Dir: $CONFIG_DIR"
    echo "  Shell Config: $SHELL_RC"
    echo ""

    if ! prompt_yes_no "Continue with installation?" "Y"; then
        print_info "Installation cancelled."
        exit 0
    fi

    check_prerequisites
    install_claude_cli
    configure_glm5_api
    create_config
    create_hooks
    create_hooks_config
    copy_skills_agents
    test_installation

    show_next_steps
}

# Run main function
main "$@"
