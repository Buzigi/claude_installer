# Claude Code Installer - Quick Start Guide

## 5-Minute Installation

### Prerequisites Check

```powershell
# Verify you have required software
node --version    # Should be 18+
npm --version     # Should be 9+
git --version     # Should be installed
```

If missing, install Node.js from https://nodejs.org/

### Installation

```powershell
# 1. Open PowerShell as Administrator
# Right-click Start > Windows PowerShell (Admin)

# 2. Navigate to installer directory
cd C:\Users\$env:USERNAME\projects\claude-installer

# 3. Allow script execution
Set-ExecutionPolicy Bypass -Scope Process -Force

# 4. Run installer
.\Install-ClaudeCode.ps1

# 5. Follow prompts
# Press Y when asked to confirm
```

### Verification

```powershell
# Run verification script
.\Verify-Installation.ps1

# All tests should pass
```

### First Run

```bash
# Start Claude Code
claude

# Try the GLM5 model
claude --model glm5 "What can you do?"

# Test a skill
claude --skill git-workflow "Create a feature branch for user-auth"

# Test an agent (this is now the default behavior)
claude --agent task-manager "Plan a login feature"
```

**Important:** With the Agent-First workflow, **every task you give Claude will automatically be delegated to an appropriate specialized agent**. You don't need to explicitly specify agents - Claude will select the best one for your task automatically.

## Agent-First Workflow

### What Is It?

The installer configures Claude Code to **always use specialized sub-agents** for every task. This means:

- Every request is automatically delegated to the most appropriate agent
- Tasks are handled by specialists with the right tools and knowledge
- Complex multi-step tasks are properly coordinated
- You get consistent, high-quality results

### How It Works

```
Your Request
    ↓
Pre-prompt hook adds: "Use an appropriate agent"
    ↓
Claude selects the best agent automatically
    ↓
Agent executes with specialized tools
    ↓
Result presented to you
```

### Permissions

The installer grants **full permissions** with safety measures:

✅ **Can do anything:**
- Read/write any file
- Execute any command
- Use any tool
- Access web APIs
- Modify code

⚠️ **With protection:**
- Delete operations require confirmation
- Protected paths (~/.claude, ~/projects) need approval
- Automatic backups before destructive operations
- Complete audit trail in logs

### Examples

```bash
# All of these will automatically use agents:

claude "Create a REST API for user management"
# → Uses: backend-architect agent

claude "Where is the authentication code?"
# → Uses: Explore or project-navigator agent

claude "Fix the failing tests"
# → Uses: test-writer-fixer agent

claude "Add a dark mode toggle"
# → Uses: frontend-developer agent

claude "Deploy to production"
# → Uses: devops-automator or project-shipper agent
```

### Available Agents

The installer includes 44+ specialized agents:

| Agent | Best For |
|-------|----------|
| task-manager | Complex multi-step tasks |
| project-navigator | Finding code, understanding structure |
| frontend-developer | UI components, React/Vue/Angular |
| backend-architect | APIs, databases, server logic |
| test-writer-fixer | Writing and fixing tests |
| devops-automator | CI/CD, deployment, infrastructure |
| git-github-specialist | Git operations, PRs, branching |
| rapid-prototyper | Quick MVPs and prototypes |
| ai-engineer | AI/ML features, LLM integration |
| Plan agent | Implementation planning |

And 30+ more specialized agents!

## What Gets Installed

### Core Components
- ✓ Claude Code CLI (latest version)
- ✓ GLM5 model configuration
- ✓ **Agent-First workflow** (always uses specialized agents)
- ✓ **Full permissions** (with delete protection)
- ✓ Configuration files (settings.json, settings.local.json)
- ✓ **Hooks system** (enforces agent usage, protects against deletes)
- ✓ 10+ skills (git-workflow, drawio, testing, etc.)
- ✓ 44+ agents (task-manager, project-navigator, etc.)
- ✓ MCP server integration
- ✓ Self-referential capabilities

### Directory Structure

```
~/.claude/
├── settings.json              # Main configuration (with agent orchestration)
├── settings.local.json        # Local settings
├── hooks/                     # Agent-First enforcement hooks
│   ├── hooks.json             # Hooks configuration
│   ├── pre-prompt.ps1         # Enforces agent usage
│   ├── pre-tool.ps1           # Delete protection
│   └── post-tool.ps1          # Operation logging
├── skills/                    # 10+ skills
├── agents/                    # 44+ agents
├── backups/                   # Automatic backups
└── logs/                      # Operation logs
```

## Common Tasks

### Create a New Skill

```bash
claude --skill claude-installer "Create a skill for Python development"

# The installer will:
# 1. Analyze your request
# 2. Create skill directory
# 3. Generate skill files
# 4. Update configuration
```

### Use a Specific Agent

```bash
# Task Manager - For complex features
claude --agent task-manager "Plan a REST API"

# Project Navigator - For code location
claude --agent project-navigator "Find authentication code"

# Software Architect - For design
claude --agent software-architect "Design a microservice architecture"
```

### Update Skills

```powershell
# Update all skills from their repositories
.\Update-Skills.ps1
```

## Troubleshooting

### "claude command not found"

```powershell
# Restart PowerShell
# Or refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

### Installation Fails

```powershell
# Run as Administrator
# Check internet connection
# Verify npm is installed: npm --version
# See TROUBLESHOOTING.md for details
```

### Skills Not Loading

```powershell
# Restart Claude Code
exit
claude

# Or update skills
.\Update-Skills.ps1
```

## Next Steps

1. **Explore Skills**: Try different skills
   ```bash
   claude --skill git-workflow "Show me Git Flow"
   claude --skill drawio "Create a flowchart"
   ```

2. **Use Agents**: Leverage specialized agents
   ```bash
   claude --agent task-manager "Plan my project"
   ```

3. **Customize**: Edit configuration
   ```powershell
   notepad ~/.claude/settings.json
   ```

4. **Learn More**: Read documentation
   - `README.md` - Main documentation
   - `docs/INSTALLATION.md` - Detailed installation
   - `docs/CONFIGURATION.md` - Configuration guide
   - `docs/TROUBLESHOOTING.md` - Troubleshooting

## Key Features

### GLM5 Model
- Optimized for Claude Code
- 8192 max tokens
- Fast response times
- Advanced reasoning

### Skills System
- Modular capabilities
- Easy to extend
- Community contributions
- Auto-update support

### Agent System
- 44+ specialized agents
- Task coordination
- Multi-agent workflows
- Self-improvement

### Self-Referential
- Create new skills
- Modify agents
- Improve itself
- Generate documentation

## Example Workflows

### Web Development

```bash
# Plan a new feature
claude --agent task-manager "Add user authentication"

# Find relevant code
claude --agent project-navigator "Locate auth code"

# Design the solution
claude --agent software-architect "Design auth system"

# Implement
claude --skill git-workflow "Create feature branch"
claude "Implement JWT authentication"
```

### Database Work

```bash
# Design database
claude --agent software-architect "Design user database schema"

# Create migrations
claude --skill database "Create migration for users table"

# Test
claude --skill testing "Write tests for user model"
```

### Documentation

```bash
# Generate docs
claude --skill documentation "Create API documentation"

# Create diagrams
claude --skill drawio "Create system architecture diagram"
```

## Getting Help

### Documentation
- Main: `README.md`
- Installation: `docs/INSTALLATION.md`
- Configuration: `docs/CONFIGURATION.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`

### Commands
```bash
# List available skills
ls ~/.claude/skills

# List available agents
ls ~/.claude/agents

# Check configuration
cat ~/.claude/settings.json

# Run verification
./Verify-Installation.ps1
```

### Support
- GitHub Issues: [claude-installer/issues]
- Community: [Discord/Slack]
- Email: support@example.com

## Tips

1. **Start Simple**: Use basic commands first
2. **Explore**: Try different skills and agents
3. **Customize**: Adjust settings for your workflow
4. **Update**: Keep skills and agents updated
5. **Backup**: Save your configuration periodically
6. **Experiment**: Use self-referential capabilities
7. **Learn**: Read the documentation
8. **Share**: Contribute back to community

## What's Next?

### Recommended Reading

1. **Configuration Guide**: `docs/CONFIGURATION.md`
2. **Agent Coordination**: `docs/MULTI-AGENT-COORDINATION-PLAN.md`
3. **Project Structure**: `docs/PROJECT-STRUCTURE.md`

### Advanced Usage

1. Create custom skills for your workflow
2. Modify agents for your needs
3. Set up MCP servers for integrations
4. Configure project-specific settings
5. Automate with scripts

### Community

1. Share your skills and agents
2. Contribute to the installer
3. Report bugs and request features
4. Help other users

---

**Installation Complete!** Welcome to Claude Code with GLM5!

**Questions?** Check the documentation or ask the community.

**Enjoy Coding!** 🚀
