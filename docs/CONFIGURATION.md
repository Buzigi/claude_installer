# Claude Code Configuration Guide

## Table of Contents

1. [Configuration Files](#configuration-files)
2. [Model Configuration](#model-configuration)
3. [Skills Configuration](#skills-configuration)
4. [Agents Configuration](#agents-configuration)
5. [Permissions](#permissions)
6. [MCP Servers](#mcp-servers)
7. [Advanced Settings](#advanced-settings)

## Configuration Files

### File Locations

```
~/.claude/
├── settings.json              # Main configuration
├── settings.local.json        # Project/local settings
├── .claude.json              # Project-specific settings
└── projects/                 # Project configurations
```

### settings.json

Main configuration file for Claude Code:

```json
{
  "model": "glm5",
  "permissions": {
    "defaultMode": "allow",
    "allowedTools": ["Bash(*)", "Read(*)", "Write(*)"],
    "deniedTools": [],
    "askBeforeUse": []
  }
}
```

### settings.local.json

Local/project-specific overrides:

```json
{
  "permissions": {
    "allow": [
      "Bash(dir:*)",
      "Bash(powershell:*)"
    ]
  }
}
```

## Model Configuration

### Available Models

```json
{
  "models": {
    "glm5": {
      "name": "GLM5",
      "maxTokens": 8192,
      "supportsStreaming": true
    },
    "opus": {
      "name": "Claude Opus",
      "maxTokens": 200000,
      "supportsStreaming": true
    },
    "sonnet": {
      "name": "Claude Sonnet",
      "maxTokens": 200000,
      "supportsStreaming": true
    },
    "haiku": {
      "name": "Claude Haiku",
      "maxTokens": 200000,
      "supportsStreaming": true
    }
  }
}
```

### Configuring GLM5

```json
{
  "model": "glm5",
  "apiEndpoint": "https://api.anthropic.com/v1/messages",
  "modelConfig": {
    "maxTokens": 8192,
    "temperature": 0.7,
    "topK": 40,
    "topP": 0.95
  }
}
```

### Model Selection

Command line:

```bash
# Use specific model
claude --model glm5

# Set default model in settings.json
{
  "model": "glm5"
}
```

## Skills Configuration

### Installing Skills

Skills are installed to `~/.claude/skills/`:

```
~/.claude/skills/
├── drawio/
│   ├── .skillfish.json
│   ├── SKILL.md
│   └── templates/
├── git-workflow/
│   ├── .skillfish.json
│   └── SKILL.md
└── testing/
    ├── .skillfish.json
    └── SKILL.md
```

### Skill Metadata

`.skillfish.json` format:

```json
{
  "version": 1,
  "owner": "username",
  "repo": "repository",
  "path": ".claude/skills/skill-name",
  "branch": "main",
  "sha": "commit-sha"
}
```

### Skill Structure

SKILL.md format:

```markdown
---
name: skill-name
description: Skill description
tools: Read, Write, Bash
---

# Skill Name

Detailed skill documentation...

## Usage

Examples and instructions...
```

### Creating Custom Skills

1. Create skill directory:

```powershell
mkdir ~/.claude/skills/my-skill
```

2. Create metadata:

```json
{
  "version": 1,
  "owner": "my-username",
  "repo": "my-skills"
}
```

3. Create SKILL.md:

```markdown
---
name: my-skill
description: My custom skill
tools: Read, Write, Bash
---

# My Skill

Instructions for using this skill...
```

### Using Skills

Command line:

```bash
# Use specific skill
claude --skill drawio "Create a flowchart"

# Combine skills
claude --skill drawio --skill git-workflow "Diagram the git flow"
```

## Agents Configuration

### Installing Agents

Agents are installed to `~/.claude/agents/`:

```
~/.claude/agents/
├── task-manager-agent.md
├── project-navigator-agent.md
├── software-architect.md
└── engineering/
    ├── backend-dev.md
    └── frontend-dev.md
```

### Agent Structure

Agent file format:

```markdown
---
name: agent-name
description: Agent description
tools: Read, Write, Bash, Glob, Grep
---

# Agent Name

Agent instructions and capabilities...

## Workflow

Step-by-step process...
```

### Creating Custom Agents

1. Create agent file:

```powershell
cat > ~/.claude/agents/my-agent.md << 'EOF'
---
name: my-agent
description: My custom agent
tools: Read, Write, Bash
---

# My Custom Agent

Purpose and capabilities...

## Workflow

1. Step one
2. Step two
3. Step three
EOF
```

2. Test agent:

```bash
claude --agent my-agent "Test task"
```

### Using Agents

Command line:

```bash
# Use specific agent
claude --agent task-manager "Plan a new feature"

# Chain agents
claude --agent project-navigator --agent software-architect "Design the system"
```

## Permissions

### Permission Levels

1. **Allow**: Automatically permit
2. **Deny**: Automatically deny
3. **Ask**: Prompt user each time

### Configuration

```json
{
  "permissions": {
    "defaultMode": "allow",
    "allowedTools": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Glob(*)",
      "Grep(*)"
    ],
    "deniedTools": [
      "Bash(rm:*)",
      "Bash(format:*)"
    ],
    "askBeforeUse": [
      "Bash(choco install:*)",
      "Write(path:*重要*)"
    ]
  }
}
```

### Permission Patterns

```json
{
  "permissions": {
    "allow": [
      "Bash(dir:*)",           // Allow listing directories
      "Bash(move:*)",          // Allow moving files
      "Read(path:*.md)",       // Allow reading markdown
      "Write(path:/tmp/*)"     // Allow writing to temp
    ]
  }
}
```

### Bypass Mode

For trusted environments:

```json
{
  "bypassPermissionsMode": true,
  "bypassPermissionsModeAccepted": true
}
```

## MCP Servers

### MCP Server Configuration

Configure in `.claude.json`:

```json
{
  "projects": {
    "C:\\Users\\YourName\\Projects": {
      "mcpServers": {
        "chrome-devtools": {
          "type": "stdio",
          "command": "npx",
          "args": ["chrome-devtools-mcp@latest"],
          "env": {}
        },
        "filesystem": {
          "type": "stdio",
          "command": "npx",
          "args": ["@modelcontextprotocol/server-filesystem"],
          "env": {}
        }
      }
    }
  }
}
```

### Available MCP Servers

```json
{
  "mcpServers": {
    "chrome-devtools": "Browser automation",
    "filesystem": "File system operations",
    "git": "Git operations",
    "postgres": "PostgreSQL database",
    "slack": "Slack integration",
    "github": "GitHub operations"
  }
}
```

## Advanced Settings

### Cache Configuration

```json
{
  "cacheEnabled": true,
  "cacheSizeMB": 512,
  "cacheTTLMinutes": 60
}
```

### History Configuration

```json
{
  "historyEnabled": true,
  "historyMaxEntries": 1000,
  "historyDaysToKeep": 30
}
```

### UI Preferences

```json
{
  "uiPreferences": {
    "theme": "dark",
    "fontSize": 14,
    "tabSize": 2,
    "showLineNumbers": true,
    "wordWrap": true,
    "autoSave": true
  }
}
```

### Feature Flags

```json
{
  "featureFlags": {
    "thinkingMode": true,
    "planMode": true,
    "streaming": true,
    "autoSave": true,
    "experimentalFeatures": false
  }
}
```

### Debug Mode

```json
{
  "debugMode": true,
  "logLevel": "debug",
  "logToFile": true,
  "logPath": "~/.claude/debug/"
}
```

## Project-Specific Configuration

### Per-Project Settings

`.claude.json` in project root:

```json
{
  "allowedTools": ["Read", "Write", "Bash"],
  "mcpServers": {
    "project-db": {
      "command": "python",
      "args": ["scripts/mcp_server.py"]
    }
  },
  "ignorePatterns": [
    "node_modules/",
    ".git/",
    "dist/"
  ]
}
```

### Project Onboarding

```json
{
  "projectOnboardingSeenCount": 4,
  "hasCompletedProjectOnboarding": true,
  "exampleFiles": [
    "README.md",
    "src/index.ts"
  ]
}
```

## Environment Variables

### Setting Environment Variables

PowerShell:

```powershell
# Temporary (current session)
$env:CLAUDE_MODEL = "glm5"

# Permanent
[Environment]::SetEnvironmentVariable("CLAUDE_MODEL", "glm5", "User")
```

### Available Variables

```bash
CLAUDE_MODEL              # Default model
CLAUDE_API_KEY           # API key
CLAUDE_CACHE_DIR         # Cache directory
CLAUDE_CONFIG_DIR        # Config directory
CLAUDE_DEBUG            # Enable debug mode
```

## Updating Configuration

### Reload Configuration

```bash
# Restart Claude Code
exit
claude
```

### Validate Configuration

```bash
# Check syntax
claude --validate-config

# Test configuration
claude --test-config
```

## Best Practices

1. **Version Control**: Keep configuration in Git
2. **Environment-Specific**: Use different configs for dev/prod
3. **Security**: Don't commit API keys
4. **Documentation**: Document custom settings
5. **Testing**: Test configuration changes in isolation

## Troubleshooting

### Configuration Not Loading

1. Check file permissions
2. Validate JSON syntax
3. Check file locations
4. Restart Claude Code

### Permissions Not Working

1. Check permission syntax
2. Verify patterns match
3. Check bypass mode settings
4. Review local overrides

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more details.
