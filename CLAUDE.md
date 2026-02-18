# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code Installer automates the complete setup of Claude Code CLI with GLM5 model configuration. It installs skills, agents, hooks, and configuration templates to enable an Agent-First workflow with full permissions and delete protection.

## Key Commands

### Installation Scripts
- **Windows**: `.\Install-ClaudeCode.ps1` (run as Administrator recommended)
- **Linux/macOS**: `./install-claude-code.sh`

### Installation Options (PowerShell)
```powershell
.\Install-ClaudeCode.ps1                    # Standard install
.\Install-ClaudeCode.ps1 -SkipCLI           # Skip CLI if already installed
.\Install-ClaudeCode.ps1 -IncludeMCP        # Include MCP servers
.\Install-ClaudeCode.ps1 -SkillsPath "..."  # Custom skills path
```

### Maintenance Scripts
- `.\Verify-Installation.ps1` - Verify installation is correct
- `.\Update-Skills.ps1` - Update skills from repository
- `.\Uninstall-ClaudeCode.ps1` - Remove Claude Code (use `-KeepConfig` to preserve settings)

## Architecture

### Configuration Layer
- `config/glm5-config.json` - GLM5 model settings, env vars, capabilities
- `config/skills-repository.json` - Skills manifest with dependencies and tags
- `config/agents-manifest.json` - 44+ agents organized by category (engineering, design, testing, etc.)

### Templates Layer (`templates/`)
- `settings.json.template` - Main Claude Code config with GLM5 env block, permissions, agent orchestration
- `settings.local.json.template` - Project-specific overrides
- `hooks.json.template` - Hook definitions for agent orchestration and delete protection
- `pre-tool-hook.ps1.template` / `pre-prompt-hook.ps1.template` - Hook implementations

### Skills Structure
Each skill in `skills/` contains:
- `.skillfish.json` - Metadata (version, owner, path)
- `SKILL.md` - Skill instructions and prompts

### Agents Structure
Agent definitions in `agents/` are markdown files with YAML frontmatter:
```yaml
---
name: agent-name
description: What this agent does
tools: Read, Write, Glob, Grep, Bash
---
```

## GLM5 Configuration

GLM5 is accessed via Zhipu AI's Anthropic-compatible proxy:
```
ANTHROPIC_BASE_URL = https://api.z.ai/api/anthropic
ANTHROPIC_DEFAULT_SONNET_MODEL = glm-5
```

The `env` block format in settings.json is required (not flat keys at root level).

## Agent-First Workflow

The installer configures Claude Code to always delegate tasks to specialized sub-agents:
```json
"agentOrchestration": {
  "enabled": true,
  "mode": "always",
  "fallbackToDirect": false
}
```

Core agents: task-manager, project-navigator, software-architect, backend-dev, frontend-dev, test-runner, devops-engineer

## Permissions Model

- Full permissions via `"defaultMode": "bypassPermissions"`
- Delete protection enabled - destructive operations require confirmation
- Protected paths: `~/.claude`, `~/projects`

## Adding New Skills/Agents

1. Create skill/agent in appropriate directory
2. Update manifest file (`config/skills-repository.json` or `config/agents-manifest.json`)
3. Test with `.\Verify-Installation.ps1`

## Remote Execution

The installer supports one-liner remote execution without cloning:
```powershell
# Windows
$f="$env:TEMP\Install-ClaudeCode.ps1"; irm https://raw.githubusercontent.com/Buzigi/claude_installer/master/Install-ClaudeCode.ps1 -OutFile $f; & $f; Remove-Item $f
```
