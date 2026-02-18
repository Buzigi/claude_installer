# Claude Code Installer - GLM5 Edition

## Overview

This installer automates the complete setup of Claude Code CLI with GLM5 model configuration, including all available skills, agents, self-referential capabilities, and **Agent-First workflow** with comprehensive permissions management.

## Features

- **Native Claude Code CLI installation** (recommended method, not deprecated npm)
- **GLM5 model configuration** with proper env block format
- **Agent-First workflow** - Always uses specialized sub-agents for every task
- **Full permissions** - Can execute any operation except delete without confirmation
- **Delete protection** - Destructive operations require explicit confirmation
- Complete skills repository installation
- Full agent suite deployment (44+ specialized agents)
- MCP server configuration
- Self-referential setup (can create its own skills)
- PowerShell-based automation for Windows
- Bash script for Linux/macOS

## System Requirements

- **Windows 10/11** or **Linux** (Ubuntu 20.04+, Debian 10+) or **macOS 13.0+**
- PowerShell 5.1+ (Windows) or Bash/Zsh (Linux/macOS)
- Internet connection
- Administrative privileges (recommended for Windows)

## Installation

### One-Liner Install (No Clone Required)

**Windows (PowerShell) - Run as Administrator:**
```powershell
$f="$env:TEMP\Install-ClaudeCode.ps1"; irm https://raw.githubusercontent.com/Buzigi/claude_installer/master/Install-ClaudeCode.ps1 -OutFile $f; & $f; Remove-Item $f -ErrorAction SilentlyContinue
```

**Linux/macOS (Bash/Zsh):**
```bash
curl -fsSL https://raw.githubusercontent.com/Buzigi/claude_installer/master/install-claude-code.sh | bash
```

**That's it.** No git clone, no downloads, no manual steps. Just run the command and follow the prompts.

---

### Alternative: Clone and Run

If you prefer to clone the repo first:

**Windows:**
```powershell
git clone https://github.com/Buzigi/claude_installer.git
cd claude_installer
.\Install-ClaudeCode.ps1
```

**Linux/macOS:**
```bash
git clone https://github.com/Buzigi/claude_installer.git
cd claude_installer
chmod +x install-claude-code.sh
./install-claude-code.sh
```

---

### Custom Install Options

**Windows (PowerShell):**
```powershell
# Custom paths
.\Install-ClaudeCode.ps1 -SkillsPath "C:\custom\skills" -AgentsPath "C:\custom\agents"

# Skip CLI installation (if already installed)
.\Install-ClaudeCode.ps1 -SkipCLI

# Include MCP servers
.\Install-ClaudeCode.ps1 -IncludeMCP
```

**Linux/macOS:**
```bash
# Custom model
MODEL=glm5 ./install-claude-code.sh

# Specific shell
SHELL=/bin/zsh ./install-claude-code.sh
```

## Project Structure

```
claude-installer/
├── Install-ClaudeCode.ps1          # Windows installation script
├── install-claude-code.sh           # Linux/macOS installation script
├── Uninstall-ClaudeCode.ps1        # Windows uninstall script
├── uninstall-claude-code.sh         # Linux/macOS uninstall script
├── config/
│   ├── glm5-config.json            # GLM5 model configuration
│   ├── skills-repository.json      # Skills manifest
│   └── agents-manifest.json        # Agents manifest
├── skills/                          # Skills to install
│   ├── drawio/
│   ├── git-workflow/
│   └── ...
├── agents/                          # Agents to install
│   ├── task-manager-agent.md
│   ├── project-navigator-agent.md
│   └── ...
├── templates/                       # Configuration templates
│   ├── settings.json.template
│   ├── settings.local.json.template
│   ├── hooks.json.template
│   ├── pre-prompt-hook.ps1.template
│   └── pre-tool-hook.ps1.template
└── docs/                            # Documentation
    ├── INSTALLATION.md              # Detailed installation guide
    ├── CONFIGURATION.md             # Configuration guide
    ├── TROUBLESHOOTING.md           # Troubleshooting
    ├── GLM5-SETUP.md               # GLM5 specific setup
    └── AGENT-FIRST-WORKFLOW.md     # Agent-First workflow guide
```

## Configuration

### Model Configuration

The installer configures Claude Code to use GLM5 model by default.

**How GLM5 Works:**

GLM5 is accessed through a Zhipu AI proxy that provides an Anthropic-compatible API:

```
Claude Code → https://api.z.ai/api/anthropic → GLM5 Model
```

**Configuration (settings.json):**
```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your_api_key_here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
  }
}
```

**Key Environment Variables:**
- `ANTHROPIC_BASE_URL` = `https://api.z.ai/api/anthropic`
- `ANTHROPIC_AUTH_TOKEN` = Your GLM5 API key (format: `id.secret`)
- `ANTHROPIC_DEFAULT_SONNET_MODEL` = `glm-5`

The installer will prompt for your API key during installation and configure everything automatically.

For detailed GLM5 setup instructions, see [docs/GLM5-SETUP.md](docs/GLM5-SETUP.md)

**Reference:** [GLM-5 in Claude Code Guide](https://aiengineerguide.com/blog/glm-5-in-claude-code/)

### Agent-First Workflow Configuration

The installer configures Claude Code to **always use specialized sub-agents** for every task:

```json
{
  "agentOrchestration": {
    "enabled": true,
    "mode": "always",
    "defaultAgent": "task-manager",
    "fallbackToDirect": false,
    "minTaskComplexity": 1,
    "preferSpecializedAgents": true
  }
}
```

This ensures that:
- Every task is delegated to the most appropriate specialist agent
- No task is executed directly without agent oversight
- Complex tasks are properly coordinated and orchestrated
- Quality and consistency are maintained across all operations

### Permissions Configuration

Full permissions are granted with delete protection:

```json
{
  "permissions": {
    "defaultMode": "allow",
    "allowedTools": [
      "Bash(*)", "Read(*)", "Write(*)", "Edit(*)",
      "Glob(*)", "Grep(*)", "Task(*)", "TaskOutput(*)",
      "WebSearch(*)", "WebFetch(*)", "Skill(*)"
    ]
  },
  "deleteProtection": {
    "enabled": true,
    "confirmBeforeDelete": true,
    "protectedPaths": ["~/.claude", "~/projects"],
    "requireConfirmationFor": ["Bash", "Edit", "Write"]
  }
}
```

**Key Features:**
- Full access to all tools and operations
- Delete operations require explicit confirmation
- Automatic backups before destructive operations
- Protected paths cannot be modified without approval

### Hooks Configuration

The installer sets up three hooks to enforce the Agent-First workflow:

1. **Pre-Prompt Hook** (`~/.claude/hooks/pre-prompt.ps1`)
   - Runs before every user prompt
   - Automatically adds agent delegation instructions
   - Ensures agent usage is enforced

2. **Pre-Tool Hook** (`~/.claude/hooks/pre-tool.ps1`)
   - Runs before every tool operation
   - Detects destructive operations
   - Requires confirmation for deletes
   - Creates automatic backups

3. **Post-Tool Hook** (`~/.claude/hooks/post-tool.ps1`)
   - Runs after every tool operation
   - Logs all operations for audit trail
   - Tracks agent activity

### Skills Configuration

Skills are installed from the skills repository and can be customized:

```json
{
  "enabledSkills": [
    "drawio",
    "git-workflow",
    "testing",
    "documentation",
    "code-review"
  ]
}
```

### Agents Configuration

All 44+ agents are installed and categorized:

- **Engineering**: backend-dev, frontend-dev, devops-engineer, ai-engineer
- **Design**: ui-designer, ux-researcher, visual-storyteller
- **Product**: product-manager, business-analyst
- **Testing**: test-runner, qa-engineer
- **Architecture**: software-architect, backend-architect
- **Project Management**: project-navigator, task-manager

## Post-Installation

### Verification

Run the verification script to ensure everything is installed correctly:

```powershell
.\Verify-Installation.ps1
```

### First Run

```bash
# Start a new Claude Code session (GLM5 is default)
claude

# Test a simple request
claude "Hello, can you confirm you're running?"

# Test a skill
claude --skill drawio

# Test an agent
claude --agent task-manager
```

## Self-Referential Capabilities

The installer includes a meta-skill that allows Claude Code to:

1. Create new skills for itself
2. Modify existing agents
3. Generate installation scripts
4. Self-document and improve

Example usage:

```bash
claude --agent task-manager "Create a new skill for database migrations"
```

## Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

## Maintenance

### Update Skills

```powershell
.\Update-Skills.ps1
```

### Update Agents

```powershell
.\Update-Agents.ps1
```

### Uninstall

Completely remove Claude Code from your system (CLI, config, env vars, PATH, caches).

**One-Liner Uninstall (No Clone Required):**

*Windows (PowerShell):*
```powershell
$f="$env:TEMP\Uninstall-ClaudeCode.ps1"; irm https://raw.githubusercontent.com/Buzigi/claude_installer/master/Uninstall-ClaudeCode.ps1 -OutFile $f; & $f; Remove-Item $f -ErrorAction SilentlyContinue
```

*Linux/macOS:*
```bash
curl -fsSL https://raw.githubusercontent.com/Buzigi/claude_installer/master/uninstall-claude-code.sh | bash
```

**From Cloned Repo:**

*Windows:*
```powershell
.\Uninstall-ClaudeCode.ps1
```

*Linux/macOS:*
```bash
chmod +x uninstall-claude-code.sh
./uninstall-claude-code.sh
```

**Options:**

| Flag | PowerShell | Bash | Description |
|------|-----------|------|-------------|
| Keep config | `-KeepConfig` | `--keep-config` | Remove CLI only, keep `~/.claude` |
| Keep env vars | `-KeepEnvVars` | `--keep-env` | Keep `ANTHROPIC_*` environment variables |
| Skip prompts | `-Force` | `--force` / `-f` | No confirmation prompts |

A backup of your configuration is automatically saved before removal.

## Contributing

To add new skills or agents to the installer:

1. Add the skill/agent to the appropriate directory
2. Update the manifest file (skills-repository.json or agents-manifest.json)
3. Test using `.\Test-Installer.ps1`
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and support:
- GitHub Issues: [claude-installer/issues](https://github.com/your-org/claude-installer/issues)
- Documentation: [docs/](docs/)
- Community: [Discord/Slack]

## Version History

- v1.0.0 - Initial release with GLM5 support
- v1.1.0 - Added self-referential capabilities
- v1.2.0 - Enhanced MCP server integration
- v2.0.0 - Agent-First workflow with full permissions and delete protection
- **v2.1.0 - Fixed GLM5 configuration format (env block), native installer (no deprecated npm)**

## Agent-First Workflow

This installer configures Claude Code to **always use specialized sub-agents** for task execution. This provides:

### Benefits
- **Consistent Quality**: Tasks handled by appropriate specialists
- **Better Orchestration**: Complex multi-step tasks properly coordinated
- **Improved Reliability**: Agents have specialized tools and knowledge
- **Full Permissions**: Can execute any operation (with delete protection)
- **Safety**: Destructive operations require confirmation

### How It Works

1. User submits a task
2. Pre-prompt hook adds agent delegation instruction
3. Claude selects the most appropriate agent automatically
4. Agent executes the task with specialized tools
5. Result presented to user

For detailed information, see [docs/AGENT-FIRST-WORKFLOW.md](docs/AGENT-FIRST-WORKFLOW.md)

### Permissions

The installer grants **full permissions** with safety measures:

- ✅ Read any file
- ✅ Write any file
- ✅ Edit any file
- ✅ Execute any Bash command
- ✅ Use any tool available
- ✅ Access web APIs
- ⚠️ Delete operations require confirmation
- ⚠️ Protected paths require explicit approval

## Acknowledgments

Built with Claude Code CLI and powered by GLM5 model.
